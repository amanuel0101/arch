#!/usr/bin/env bash

set -e

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

LOGO_PATH="$HOME/logo.txt"
LOGO_WIDTH=$(awk '{ if (length > max) max = length } END { print max+0 }' "$LOGO_PATH")

USERNAME_PATTERN='^[a-z_][a-z0-9_-]*[$]?$'
RESERVED_USERNAMES='^(root|bin|daemon|mail|ftp|http|nobody|dbus|systemd-coredump|systemd-network|systemd-oom|systemd-journal-remote|systemd-resolve|systemd-timesync|tss|uuidd|alpm|git|avahi|cups|lp|_talkd|polkitd|rtkit|qemu|brltty|gluster|rpc|libvirt-qemu|pcscd|nvidia-persistenced|sddm)$'
HOSTNAME_PATTERN='^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
HOSTNAME_DEFAULT='arch'

export GUM_CONFIRM_PROMPT_FOREGROUND="6"
export GUM_CONFIRM_SELECTED_FOREGROUND="0"
export GUM_CONFIRM_SELECTED_BACKGROUND="2"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="7"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="0"

READY_TO_INSTALL=false
USER_FORM_CONFIRMED=false
DISK_FORM_CONFIRMED=false

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

measure_terminal() {
  TERM_WIDTH=$(stty size 2>/dev/null </dev/tty | awk '{print $2}')
  ((TERM_WIDTH > 0)) || TERM_WIDTH=${COLUMNS:-80}

  PADDING_LEFT=$(((TERM_WIDTH - LOGO_WIDTH) / 2))
  ((PADDING_LEFT < 0)) && PADDING_LEFT=0
  PADDING_LEFT_SPACES=$(printf "%*s" "$PADDING_LEFT" "")

  PADDING="0 0 0 $PADDING_LEFT"
  export GUM_CHOOSE_PADDING="$PADDING"
  export GUM_FILTER_PADDING="$PADDING"
  export GUM_INPUT_PADDING="$PADDING"
  export GUM_SPIN_PADDING="$PADDING"
  export GUM_TABLE_PADDING="$PADDING"
  export GUM_CONFIRM_PADDING="$PADDING"
}

clear_logo() {
  measure_terminal
  printf "\033[H\033[2J"
  gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "$(<"$LOGO_PATH")"
  echo
}

notice() {
  clear_logo
  gum spin --spinner "pulse" --title "$1" -- sleep "${2:-5}"
}

spin() {
  clear_logo
  gum spin --title "$1" --spinner line --padding "0 0 0 $PADDING_LEFT" -- bash -c "$2"
}

style() {
  clear_logo
  gum style --foreground $1 --padding "0 0 0 $PADDING_LEFT" "$2"
}

set_tokyo_night_colors() {
  #echo -en "\e]P01a1b26"
  echo -en "\e]P1f7768e"
  echo -en "\e]P29ece6a"
  echo -en "\e]P3e0af68"
  echo -en "\e]P47aa2f7"
  echo -en "\e]P5bb9af7"
  echo -en "\e]P67dcfff"
  echo -en "\e]P7a9b1d6"
  echo -en "\e]P8414868"
  echo -en "\e]P9f7768e"
  echo -en "\e]PA9ece6a"
  echo -en "\e]PBe0af68"
  echo -en "\e]PC7aa2f7"
  echo -en "\e]PDbb9af7"
  echo -en "\e]PE7dcfff"
  echo -en "\e]PFc0caf5"
  echo -en "\033[0m"
  clear
}
set_tokyo_night_colors

# ---------------------------------------------------------
# Keyboard
# ---------------------------------------------------------

KEYBOARD_LAYOUTS=$'English (US)|us
English (UK)|uk
English (US, Dvorak)|dvorak
English (US, Colemak)|colemak
Azerbaijani|azerty
Belarusian|by
Belgian|be-latin1
Bulgarian|bg-cp1251
Croatian|croat
Czech|cz
Danish|dk-latin1
Dutch|nl
Estonian|et
Finnish|fi
French|fr
French (Canada)|cf
French (Switzerland)|fr_CH
Georgian|ge
German|de
German (Switzerland)|de_CH-latin1
Greek|gr
Hebrew|il
Hungarian|hu
Icelandic|is-latin1
Irish|ie
Italian|it
Japanese|jp106
Kazakh|kazakh
Kyrgyz|kyrgyz
Lao|la-latin1
Latvian|lv
Lithuanian|lt
Macedonian|mk-utf
Norwegian|no-latin1
Polish|pl
Portuguese|pt-latin1
Portuguese (Brazil)|br-abnt2
Romanian|ro
Russian|ru
Serbian|sr-latin
Slovak|sk-qwertz
Slovenian|slovene
Spanish|es
Spanish (Latin American)|la-latin1
Swedish|sv-latin1
Tajik|tj_alt-UTF8
Turkish|trq
Ukrainian|ua'

prompt_keyboard() {
  local choice status
  choice=$(printf '%s\n' "$KEYBOARD_LAYOUTS" | cut -d'|' -f1 |
    gum choose --height 10 --selected "English (US)" --header "Select keyboard layout") && status=0 || status=$?
  ((status == 0)) || return $status

  keyboard_label="$choice"
  keyboard=$(printf '%s\n' "$KEYBOARD_LAYOUTS" | awk -F'|' -v c="$choice" '$1==c{print $2; exit}')
}

# ---------------------------------------------------------
# Username
# ---------------------------------------------------------

username_taken() { return 1; } # not implemented

prompt_username() {
  local status
  while true; do
    username=$(gum input --placeholder "Alphanumeric without spaces (like abebe)" --prompt.foreground=57 --prompt "Username> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ "$username" =~ $USERNAME_PATTERN ]]; then
      if [[ "$username" =~ $RESERVED_USERNAMES ]]; then
        notice "Username is reserved for system"
      elif username_taken "$username"; then
        notice "That username already exists on this machine"
      else
        return 0
      fi
    else
      notice "Username must be alphanumeric with no spaces"
    fi
  done
}

# ---------------------------------------------------------
# Password
# ---------------------------------------------------------

prompt_password() {
  local status
  local password_confirmation
  local plain_password

  while true; do
    plain_password=$(gum input --placeholder "Used for user + root, and disk encryption when enabled" --prompt.foreground=57 --password --prompt "Password> ") && status=0 || status=$?
    ((status == 0)) || return $status
    password_confirmation=$(gum input --placeholder "Must match the password you just typed" --prompt.foreground=57 --password --prompt "Confirm> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ -n "$plain_password" && "$plain_password" == "$password_confirmation" ]]; then
      password=$(printf '%s' "$plain_password" | openssl passwd -6 -stdin)
      unset plain_password password_confirmation
      return 0
    elif [[ -z "$plain_password" ]]; then
      notice "Your password can't be blank!"
    else
      notice "Passwords didn't match!"
    fi
  done
}

# ---------------------------------------------------------
# hostname
# ---------------------------------------------------------

prompt_hostname() {
  local status
  while true; do
    hostname=$(gum input --placeholder "Letters, digits, and dashes (or return for '$HOSTNAME_DEFAULT')" --prompt.foreground=57 --prompt "Hostname> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ -z $hostname ]]; then
      hostname="$HOSTNAME_DEFAULT"
      return 0
    elif [[ "$hostname" =~ $HOSTNAME_PATTERN ]]; then
      return 0
    else
      notice "Hostname must be 1-63 letters, digits, or dashes, and cannot start or end with a dash"
    fi
  done
}

# ---------------------------------------------------------
# timezone
# ---------------------------------------------------------

prompt_timezone() {
  local guess status
  guess=$(tzupdate -p 2>/dev/null) || guess=""

  if [[ -n $guess ]]; then
    timezone=$(timedatectl list-timezones | gum choose --height 10 --selected "$guess" --header "Timezone") && status=0 || status=$?
  else
    timezone=$(timedatectl list-timezones | gum filter --height 10 --header "Timezone") && status=0 || status=$?
  fi
  ((status == 0)) || return $status

  [[ -n $timezone ]] || timezone="UTC"
}

# ---------------------------------------------------------
# invoke and validate
# ---------------------------------------------------------

confirm_user_form() {
  echo -e "Field, Value
Username,$username
Password,"********"
Hostname,$hostname
Timezone,$timezone
Keyboard,$keyboard" |
    gum table -p | sed "s/^/${PADDING_LEFT_SPACES}/"
  echo
  if gum confirm --negative "No, change it" "Does this look right?"; then
    return 0
  else
    return 1
  fi
}

user_form() {
  while true; do
    clear_logo
    prompt_keyboard || return 1
    prompt_username || return 1
    prompt_password || return 1
    prompt_hostname || return 1
    prompt_timezone || return 1

    if confirm_user_form; then
      USER_FORM_CONFIRMED=true
      clear_logo
      break
    fi
  done
}

# ---------------------------------------------------------
# disk
# ---------------------------------------------------------

get_root_disk() {
  local device="$1"
  local parent

  [[ -n $device ]] || return 1

  # /run/archiso/bootmnt usually resolves to the boot partition, but the
  # installer picker works with whole disks. Walk back to the parent disk so
  # the install media itself never shows up as a wipe target.
  device=$(readlink -f "$device" 2>/dev/null || printf "%s\n" "$device")

  while true; do
    parent=$(lsblk -dno PKNAME "$device" 2>/dev/null | tail -n1)
    [[ -n $parent ]] || break
    device="/dev/$parent"
  done

  if [[ $(lsblk -dno TYPE "$device" 2>/dev/null) == "disk" ]]; then
    printf "%s\n" "$device"
  fi
}

get_disk_info() {
  local device="$1"
  local size vendor model label

  size=$(lsblk -dno SIZE "$device" 2>/dev/null)
  vendor=$(lsblk -dno VENDOR "$device" 2>/dev/null | sed 's/ *$//')
  model=$(lsblk -dno MODEL "$device" 2>/dev/null | sed 's/ *$//')

  label=""
  if [[ -n $vendor && -n $model ]]; then
    if [[ $model == *"$vendor"* ]]; then
      label="$model"
    else
      label="$vendor $model"
    fi
  elif [[ -n $model ]]; then
    label="$model"
  elif [[ -n $vendor ]]; then
    label="$vendor"
  fi

  local display="$device"
  [[ -n $size ]] && display="$display ($size)"
  [[ -n $label ]] && display="$display - $label"

  local part_summary
  part_summary=$(lsblk -nro TYPE,NAME,FSTYPE,MOUNTPOINT "$device" 2>/dev/null |
    awk '$1=="part" { printf "%s%s%s", s, ($3==""?"unknown":$3), ($4==""?"":"("$4")"); s=", " }')
  [[ -n $part_summary ]] && display+=" [$part_summary]"

  echo "$display"
}

select_install_disk() {
  # Don't offer the install media as an option (Arch ISO mounts it here)
  local boot_source
  local exclude_disk
  local disk_info

  boot_source=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)
  exclude_disk=$(get_root_disk "$boot_source")

  # List all installable disks, excluding the boot device if present
  local available_disks
  available_disks=$(
    lsblk -dpno NAME,TYPE |
      awk '$2=="disk"{print $1}' |
      grep -E '/dev/(sd|hd|vd|nvme|mmcblk|xv)' |
      { if [[ -n "$exclude_disk" ]]; then grep -Fvx "$exclude_disk"; else cat; fi; }
  )

  # Get available disks and format them with info
  local disk_options=""
  while IFS= read -r device; do
    if [[ -n "$device" ]]; then
      disk_info=$(get_disk_info "$device")
      disk_options="$disk_options$disk_info"$'\n'
    fi
  done <<<"$available_disks"

  local selected

  if [[ -z $available_disks ]]; then
    style 1 "No installable disks found"
    return 1
  fi

  selected=$(echo "$disk_options" | gum choose --header "Installation Disk" --height 10) || return 1

  install_disk=$(awk '{print $1}' <<<"$selected")

  [[ -b "$install_disk" ]]
}

choose_disk_mode() {
  local choice

  choice=$(printf '%s\n' "Use entire disk" "Select a partition" | gum choose --header "How do you want to install?") || return 1

  case "$choice" in
  "Use entire disk")
    install_mode="disk"
    ;;

  "Select a partition")
    install_mode="partition"
    ;;

  *)
    return 1
    ;;
  esac
}

select_install_partition() {
  local selected

  # lsblk -nrpo NAME,TYPE "$install_disk" |
  #   awk '$2 == "part" { print $1 }'
  #   [[ $(lsblk -no TYPE "$selected") == "part" ]]

  while true; do
    selected=$(
      {
        lsblk -n "$install_disk"
        printf '%s\n' "Create a new partition"
      } | gum choose --header "Select Installation Partition" --height 12
    ) || return 1

    if [[ "$selected" == "Create a new partition" ]]; then
      if ! cfdisk "$install_disk"; then
        style 3 "You can run the installer again with: ~/installer.sh"
        return 1
      fi
      clear_logo
      continue
    elif [[ "$(lsblk -no TYPE "$selected")" != "part" ]]; then
      continue
    fi

    install_partition=$(sed -E 's/^[^a-zA-Z0-9]*//' <<<"$selected" | awk '{print $1}')
    install_partition="/dev/$install_partition"

    if [[ -b "$install_partition" ]]; then
      return 0
    fi
  done
}

confirm_disk_form() {
  local mode

  case "$install_mode" in
  "disk")
    mode="Entire disk"
    ;;

  "partition")
    mode="Partition"
    ;;

  *)
    return 1
    ;;
  esac

  printf '%s\n' \
    'Field, Value' \
    "Disk,$install_disk" \
    "Mode,$mode" \
    "$(if [[ "$install_mode" == "partition" ]]; then
      printf 'Partition,%s' "$install_partition"
    fi)" |
    gum table -p | sed "s/^/${PADDING_LEFT_SPACES}/"
  echo
  if gum confirm --negative "No, change it" "Does this look right?"; then
    return 0
  else
    return 1
  fi
}

disk_form() {
  while true; do
    clear_logo
    select_install_disk || return 1
    choose_disk_mode || return 1
    if [[ "$install_mode" == "partition" ]]; then
      select_install_partition || return 1
    fi

    if confirm_disk_form; then
      DISK_FORM_CONFIRMED=true
      clear_logo
      break
    fi
  done
}

confirm_installation() {
  local prompt
  local affirm

  while true; do
    if ! $USER_FORM_CONFIRMED; then
      notice "Fill the user form!"
      user_form
      continue
    fi

    if ! $DISK_FORM_CONFIRMED; then
      notice "Fill the disk form!"
      disk_form
      continue
    fi

    if [[ "$install_mode" == "disk" ]]; then
      prompt="Everything on $install_disk will be overwritten. Are you sure you want to install?"
      affirm="Yes, format disk and install"
    else
      prompt="Partition $install_partition will be overwritten. Do you want to install?"
      affirm="Yes, install"
    fi

    if gum confirm --prompt.foreground 1 --affirmative "$affirm" --negative "No, change it" "$prompt"; then
      READY_TO_INSTALL=true
      break
    else
      disk_form
    fi
  done
}

partition_disk() {

  if [[ "$install_mode" == "disk" ]]; then
    # partition
    spin "Creating partitions..." "sfdisk \"$install_disk\" <<EOF
label: gpt
size=600M, type=c12a7328-f81f-11d2-ba4b-00a0c93ec93b
type=0fc63daf-8483-4772-8e79-3d69d8477de4
EOF" || {
      style 1 "Failed to create partitions"
      return 1
    }

    spin "Announcing partitions..." "partprobe \"$install_disk\"" || {
      style 1 "Failed to announce new partition"
      return 1
    }

    spin "Naming partitions..." "udevadm settle" || {
      style 1 "Failed to name partition"
      return 1
    }

    root_partition=$(
      lsblk -nrpo NAME,PARTTYPE "$install_disk" |
        awk 'tolower($2) == "0fc63daf-8483-4772-8e79-3d69d8477de4" {print $1; exit}' || {
        style 1 "Failed to extract root_partition"
        return 1
      }
    )

    if [[ ! -b "$root_partition" ]]; then
      style 1 "Installation partition does not exist: $root_partition"
      return 1
    fi

    spin "Formatting $root_partition..." "mkfs.ext4 -F $root_partition" || {
      style 1 "Failed to format $root_partition."
      return 1
    }

  elif [[ "$install_mode" == "partition" ]]; then
    root_partition="$install_partition"

    if [[ ! -b "$root_partition" ]]; then
      style 1 "Installation partition does not exist: $root_partition"
      return 1
    fi

    spin "Formatting $root_partition..." "mkfs.ext4 -F '$root_partition'" || {
      style 1 "Failed to format $root_partition."
      return 1
    }
  else
    clear_logo
    style 1 "Invalid installation mode: '$install_mode'"
    return 1
  fi
}

mount_disk() { # check before and after mounting
  mkdir -p /mnt || {
    style 1 "Failed to create /mnt."
    return 1
  }

  spin "Mounting $root_partition..." "mount $root_partition /mnt" || {
    style 1 "Failed to mount $root_partition."
    return 1
  }
}

setup_efi_partition() { # verify mount
  efi_partition=$(
    lsblk -nrpo NAME,PARTTYPE $install_disk |
      awk 'tolower($2) == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1; exit}' || {
      style 1 "Failed to extract efi_partition"
      return 1
    }
  )

  if [[ -z $efi_partition ]]; then
    style 1 "No EFI System Partition found on $install_disk"
    return 1
  fi

  if [[ "$install_mode" == "disk" ]]; then
    spin "Formatting $efi_partition..." "mkfs.fat -F 32 $efi_partition" || {
      style 1 "Failed to format $efi_partition"
      return 1
    }
  fi

  mkdir -p /mnt/boot || {
    style 1 "Failed to create /mnt/boot"
    return 1
  }

  spin "Mounting EFI partition..." "mount $efi_partition /mnt/boot" || {
    style 1 "Failed to mount $efi_partition"
    return 1
  }
}

install_base() {
  spin "installing base pkgs..." "pacstrap -C /etc/pacman.conf -K /mnt base base-devel linux linux-firmware networkmanager sudo grub efibootmgr" || {
    style 1 "Failed to install the base system."
    return 1
  }

  notice "base system install complete" 2
}

configure_options() {
  # set keyboard layout
  spin "Setting keyboard layout..." "arch-chroot /mnt localectl set-keymap '$keyboard'" || {
    notice "Failed to set keyboard layout"
  }

  # create username
  spin "Creating user ['$username']..." "arch-chroot /mnt useradd -m -G wheel '$username'" || {
    style 1 "Failed to create user"
    return 1
  }

  spin "Giving $username root access..." "arch-chroot /mnt sh -c \"printf '%s\n' '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel\"" || {
    style 1 "Failed to give root access to user"
    return 1
  }

  # set passwords
  spin "Setting root password..." "arch-chroot /mnt sh -c 'echo root:\$1 | chpasswd -e' -- '$password'" || {
    style 1 "Failed to set root password- $password"
    return 1
  }

  spin "Setting password for user [$username]..." "arch-chroot /mnt sh -c 'echo \$1:\$2 | chpasswd -e' -- '$username' '$password'" || {
    style 1 "Failed to set passord- $password"
    return 1
  }

  # set hostname
  spin "Setting hostname..." "arch-chroot /mnt sh -c \"echo $hostname > /etc/hostname\"" || {
    style 1 "Failed to set hostname- $hostname"
    return 1
  }

  # set nameserver
  spin "Writing nameservers..." "arch-chroot /mnt sh -c \"printf 'nameserver 1.1.1.1\\nnameserver 8.8.8.8\\n' > /etc/resolv.conf\"" || {
    style 1 "Failed to write nameservers"
    return 1
  }

  # setup grub
  spin "Installing grub..." "arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB" || {
    style 1 "Failed to install grub"
    return 1
  }

  spin "Configuring grub" "arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg" || {
    style 1 "Failed to grub-mkconfig"
    return 1
  }

  #set timezone
  spin "Setting timezone..." \
    "arch-chroot /mnt ln -sf '/usr/share/zoneinfo/$timezone' /etc/localtime" || {
    style 1 "Failed to set timezone"
    return 1
  }

  spin "Generating hardware clock configuration..." \
    "arch-chroot /mnt hwclock --systohc" || {
    style 1 "Failed to generate hardware clock configuration"
    return 1
  }

  # enable NetworkManager
  spin "Starting NM" "arch-chroot /mnt systemctl enable NetworkManager" || {
    notice "Failed to start NM"
  }
}

gen_fstab() {
  spin "Generating fstab..." "genfstab -U /mnt >/mnt/etc/fstab" || {
    style 1 "Failed to generate fstab."
    return 1
  }
  clear_logo
}

install_extras() {
  spin "Installing fonts..." "pacstrap -C /etc/pacman.conf -K /mnt ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji" || {
    notice "Failed to install fonts"
  }

  spin "Installing hyprland, git, chromium, playerctl, yazi, quickshell, gnome-calculator, hyprpaper, bluetui, upower, fish..." "pacstrap -C /etc/pacman.conf -K /mnt hyprland git chromium yazi quickshell gnome-calculator hyprpaper bluetui upower playerctl fish" || {
    style 1 "Failed to install extra packages"
    return 1
  }

  spin "Installing wlctl..." "cp /root/bin/wlctl /mnt/usr/local/bin/wlctl" || {
    notice "Failed to install wlctl"
  }
}

post_config() {
  spin "Setting autologin..." "arch-chroot /mnt sh -c \"mkdir -p /etc/systemd/system/getty@tty1.service.d && printf '[Service]\\nExecStart=\\nExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $username --noreset --noclear - \\\$TERM\\n' > /etc/systemd/system/getty@tty1.service.d/autologin.conf\"" || {
    notice "Failed to setup autologin"
  }

  spin "Setting hyprland auto start..." "arch-chroot /mnt runuser -u $username -- sh -c \"printf 'if [[ -z \\\$DISPLAY && \\\$(tty) == /dev/tty1 ]]; then\\nexec start-hyprland &>/dev/null\\nfi' > /home/$username/.bash_profile\"" || {
    notice "Failed to setup hyprland to auto start"
  }
}

check_internet() {
  if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    return 1
  fi
  return 0
}

setup_mirrorlist() {
  spin "Creating mirror list..." "reflector --latest 10 --protocol https --age 12 --sort rate --save /mnt/etc/pacman.d/mirrorlist 2>/dev/null" || {
    notice "Reflector failed, using fallback option"
    spin "Writing hardcoded mirrorlists..." "arch-chroot /mnt bash -c \"echo '
##
## Arch Linux repository mirrorlist
## Generated on 2026-09-03
##

## Worldwide
Server = https://fastly.mirror.pkgbuild.com/\$repo/os/\$arch
Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch
Server = https://ftpmirror.infania.net/mirror/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist\""
  }
}

install_arch() {
  if [[ $READY_TO_INSTALL != true ]]; then
    style 1 "not ready to install!"
    return 1
  fi

  # partitioning
  partition_disk || return 1

  # mount
  mount_disk || return 1

  # detect and mout EFI
  setup_efi_partition || return 1

  # install core packages
  install_base || return 1

  # configuration
  configure_options || return 1

  # fstab
  gen_fstab || return 1

}

setup_hyprland() {
  # terminal
  spin "installing foot..." "cp /root/bin/foot /mnt/usr/local/bin/ && cp /root/bin/footclient /mnt/usr/local/bin/" || {
    notice "Failed to install foot"
  }
  # set fish as default for user
  spin "setting fish as the default shell" "arch-chroot /mnt chsh -s /usr/bin/fish $username" || {
    notice "Failed to set fish as default"
  }

  # wallpaper
  spin "Setting default wallpaper..." "arch-chroot /mnt mkdir -p /home/$username/.config/current && cp /root/configs/background.jpg /mnt/home/$username/.config/current/background.jpg" || {
    notice "Failed to set wallpaper"
  }

  # configs
  spin "Setting up hyprland..." "cp -a /root/configs/hypr /mnt/home/$username/.config/" || {
    notice "Failed to setup hyprland"
  }
}

setup_quickshell() {
  return 0
}

handle_exit() {
  # umount
  echo "Umountting..."
  umount -R /mnt 2>/dev/null || return 1
}

start_install() {
  user_form || {
    handle_exit
    return 1
  }

  disk_form || {
    handle_exit
    return 1
  }

  confirm_installation || {
    handle_exit
    return 1
  }

  install_arch || {
    handle_exit
    return 1
  }

  # install extras
  install_extras || {
    handle_exit
    return 1
  }

  setup_hyprland || {
    handle_exit
    return 1
  }

  setup_quickshell || {
    handle_exit
    return 1
  }

  # autostart
  post_config

  # mirrorlist
  setup_mirrorlist || return 1

  # upgrade system
  if gum confirm "do you want to do a full system upgrade?"; then
    spin "Downloading latest pkgs..." "arch-chroot /mnt pacman -Syu" || {
      notice "Failed to update pkgs"
    }
  fi

  if gum confirm --negative "Later" "Reboot now?"; then
    reboot now
  fi

}

if ! start_install; then
  exit 1
fi

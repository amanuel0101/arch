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

PURPLE="57"
PINK="212"

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
  gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "$(<"$LOGO_PATH")"
  echo
}

notice() {
  clear_logo
  gum spin --spinner "pulse" --title "$1" -- sleep "${2:-10}"
}

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
# Username
# ---------------------------------------------------------

username_taken() { return 1; }

prompt_username() {
  local status
  while true; do
    username=$(gum input --placeholder "Alphanumeric without spaces (like abebe)" --prompt.foreground="$PURPLE" --prompt "Username> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ "$username" =~ $USERNAME_PATTERN ]]; then
      if [[ "$username" =~ $RESERVED_USERNAMES ]]; then
        notice "Username is reserved for system" 1
      elif username_taken "$username"; then
        notice "That username already exists on this machine" 1
      else
        return 0
      fi
    else
      notice "Username must be alphanumeric with no spaces" 1
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
    plain_password=$(gum input --placeholder "Used for user + root, and disk encryption when enabled" --prompt.foreground="$PURPLE" --password --prompt "Password> ") && status=0 || status=$?
    ((status == 0)) || return $status
    password_confirmation=$(gum input --placeholder "Must match the password you just typed" --prompt.foreground="$PURPLE" --password --prompt "Confirm> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ -n "$plain_password" && "$plain_password" == "$password_confirmation" ]]; then
      password=$(printf '%s' "$plain_password" | openssl passwd -6 -stdin)
      unset plain_password password_confirmation
      return 0
    elif [[ -z "$password" ]]; then
      notice "Your password can't be blank!" 1
    else
      notice "Passwords didn't match!" 1
    fi
  done
}

# ---------------------------------------------------------
# hostname
# ---------------------------------------------------------

prompt_hostname() {
  local status
  while true; do
    hostname=$(gum input --placeholder "Letters, digits, and dashes (or return for '$HOSTNAME_DEFAULT')" --prompt.foreground="$PURPLE" --prompt "Hostname> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ -z $hostname ]]; then
      hostname="$HOSTNAME_DEFAULT"
      return 0
    elif [[ "$hostname" =~ $HOSTNAME_PATTERN ]]; then
      return 0
    else
      notice "Hostname must be 1-63 letters, digits, or dashes, and cannot start or end with a dash" 1
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

confirm_user_form() {
  echo -e "Field, Value
Username,$username
Password,"********"
Hostname,$hostname
Timezone,$timezone" |
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
    notice "No installable disks found" 2
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
        gum style "You can run the installer again with: ~/installer.sh"
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

    if gum confirm --affirmative "$affirm" --negative "No, change it" "$prompt"; then
      READY_TO_INSTALL=true
      break
    else
      disk_form
    fi
  done
}

spin() {
  clear_logo
  gum spin --title "$1" --spinner line --padding "0 0 0 $PADDING_LEFT" -- bash -c "$2"
}

style() {
  clear_logo
  gum style --foreground $1 --padding "0 0 0 $PADDING_LEFT" "$2"
}

partition_disk() {

  if [[ "$install_mode" == "disk" ]]; then
    # partition
    spin "Creating partitions..." "sfdisk \"$install_disk\" <<EOF
label: gpt
size=600M, type=c12a7328-f81f-11d2-ba4b-00a0c93ec93b
type=0fc63daf-8483-4772-8e79-3d69d8477de4
EOF" || {
      notice "Failed to create partitions"
      return 1
    }

    spin "Announcing partitions..." "partprobe \"$install_disk\"" || {
      notice "Failed to announce new partition"
      return 1
    }

    spin "Naming partitions..." "udevadm settle" || {
      notice "Failed to name partition"
      return 1
    }

    root_partition=$(
      lsblk -nrpo NAME,PARTTYPE "$install_disk" |
        awk 'tolower($2) == "0fc63daf-8483-4772-8e79-3d69d8477de4" {print $1; exit}'
    )

    if [[ ! -b "$root_partition" ]]; then
      gum style \
        --foreground="1" \
        "Installation partition does not exist: $root_partition"
      return 1
    fi

    if ! gum confirm "Format $root_partition as ext4?"; then
      notice "Formatting partition aborted!"
      return 1
    fi

    spin "Formatting $root_partition..." "mkfs.ext4 -F $root_partition" || {
      gum style --foreground="1" "Failed to format $root_partition."
      return 1
    }

    # format EFI

  elif [[ "$install_mode" == "partition" ]]; then
    root_partition="$install_partition"

    if [[ ! -b "$root_partition" ]]; then
      gum style \
        --foreground="1" \
        "Installation partition does not exist: $root_partition"
      return 1
    fi
    if ! gum confirm "Format $root_partition as ext4?"; then
      clear_logo
      echo "Formatting partition aborted!"
      return 1
    fi

    spin "Formatting $root_partition..." "mkfs.ext4 -F $root_partition" || {
      gum style --foreground="1" "Failed to format $root_partition."
      return 1
    }
  else
    clear_logo
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Invalid installation mode: '$install_mode'"
    return 1
  fi
}

mount_disk() { # check before and after mounting
  mkdir -p /mnt || {
    gum style --foreground 1 "Failed to create /mnt."
    return 1
  }

  spin "Mounting $root_partition..." "mount $root_partition /mnt" || {
    gum style --foreground 1 "Failed to mount $root_partition."
    return 1
  }
}

setup_efi_partition() { # verify mount
  efi_partition=$(
    lsblk -nrpo NAME,PARTTYPE $install_disk |
      awk 'tolower($2) == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1; exit}'
  )

  if [[ -z $efi_partition ]]; then
    gum style --foreground 1 "No EFI System Partition found on $install_disk"
    return 1
  fi

  spin "Formatting $efi_partition..." "mkfs.fat -F 32 $efi_partition" || {
    gum style --foreground 1 "Failed to format $efi_partition"
    return 1
  }

  mkdir -p /mnt/boot || {
    gum style --foreground 1 "Failed to create /mnt/boot"
    return 1
  }

  spin "Mounting EFI partition..." "mount $efi_partition /mnt/boot" || {
    gum style --foreground 1 "Failed to mount $efi_partition"
    return 1
  }
}

install_base() {
  spin "initializing pacman keyring..." "pacman-key --init" || {
    gum style --foreground 1 "Failed to initialize pacman keyring."
    #return 1
  }

  pacstrap -C /etc/pacman.conf -K /mnt base base-devel linux linux-firmware networkmanager hyprland sudo grub efibootmgr git || {
    gum style --foreground 1 "Failed to install the base system."
    return 1
  }

  notice "base system install complete."
}

gen_fstab() {
  style 3 "Generating fstab..."
  genfstab -U /mnt >/mnt/etc/fstab || {
    notice "Failed to generate fstab."
    return 1
  }
  clear_logo
}

run_arch_chroot() { # UNSAFE!!!!!!
  spin "Setting timezone..." "arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /etc/localtime" || {
    notice "Failed to set timezone"
    return 1
  }

  spin "Generating the hardware clock configuration..." "arch-chroot /mnt hwclock --systohc" || {
    notice "Failed to generate the hw clock configuration"
    return 1
  }

  spin "Configuring locale..." "arch-chroot /mnt sh -c \"sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && echo 'LANG=en_US.UTF-8' > /etc/locale.conf\"" || {
    notice "Failed to configure locale"
    return 1
  }

  spin "Setting hostname..." "arch-chroot /mnt sh -c \"echo $hostname > /etc/hostname\"" || {
    notice "Failed to set hostname- $hostname"
    return 1
  }

  spin "Setting root password..." "arch-chroot /mnt sh -c 'echo root:\$1 | chpasswd -e' -- '$password'" || {
    notice "Failed to set root password- $password"
    return 1
  }

  spin "Creating the user..." "arch-chroot /mnt useradd -m -G wheel $username" || {
    notice "Failed to create user"
    return 1
  }

  spin "Setting password for $username..." "arch-chroot /mnt sh -c 'echo \$1:\$2 | chpasswd -e' -- '$username' '$password'" || {
    notice "Failed to set passord- $password"
    return 1
  }

  # validate ???????
  spin "Giving $username root access..." "arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers" || {
    notice "Failed to give root access to user"
    return 1
  }

  style 2 "Enabling networkmanager..."
  arch-chroot /mnt systemctl enable NetworkManager || {
    notice "Failed to enable networkmanager"
    return 1
  }

  spin "Installing grub..." "arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB" || {
    notice "Failed to install grub"
    return 1
  }

  spin "Configuring grub" "arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg" || {
    notice "Failed to grub-mkconfig"
    return 1
  }

  spin "Creating pacman mirrorlist..." "arch-chroot /mnt sh -c  'pacman -S --noconfirm --needed refector && reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'" || {
    notice "Failed to create mirrorlist"
  }

  style 2 "Syncing pacman..."
  arch-chroot /mnt pacman -Sy || {
    notice "Failed to sync pacman"
    return 1
  }

  spin "Writing nameservers..." "arch-chroot /mnt sh -c \"printf 'nameserver 1.1.1.1\\nnameserver 8.8.8.8\\n' > /etc/resolv.conf\"" || {
    notice "Failed to write nameservers"
    return 1
  }

  style 2 "Installing yay..."
  arch-chroot /mnt sh -c "printf '%s\n' '$username ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/temp-install"
  arch-chroot /mnt chmod 440 /etc/sudoers.d/temp-install

  arch-chroot /mnt su - "$username" -c '
  export GODEBUG=netdns=go
  git clone https://aur.archlinux.org/yay.git /tmp/yay &&
  cd /tmp/yay &&
  makepkg -si --noconfirm
  ' || {
    arch-chroot /mnt rm -f /etc/sudoers.d/temp-install
    notice "Failed to install yay"
    return 1
  }
  notice "Initial configuration successful"
}

install_extras() {
  # fonts
  style 2 "Installing fonts..."
  pacstrap -C /etc/pacman.conf -K /mnt ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

  style 2 "Installing foot, chromium, yazi, quickshell, gnome-calculator, rofi, hyprpaper, bluetui, upower..."
  pacstrap -C /etc/pacman.conf -K /mnt foot chromium yazi quickshell gnome-calculator rofi-wayland hyprpaper bluetui upower

  style 2 "Installing wlctl..."
  arch-chroot /mnt runuser -u "$username" -- yay --noconfirm -S wlctl-bin || {
    notice "Failed to install wlctl"
  }
  arch-chroot /mnt rm -f /etc/sudoers.d/temp-install
}

post_config() {
  spin "Setting autologin..." "arch-chroot /mnt sh -c \"mkdir -p /etc/systemd/system/getty@tty1.service.d && printf '[Service]\\nExecStart=\\nExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $username --noreset --noclear - \\\$TERM\\n' > /etc/systemd/system/getty@tty1.service.d/autologin.conf\"" || {
    notice "Failed to setup autologin"
  }

  spin "Setting hyprland auto start..." "arch-chroot /mnt runuser -u $username -- sh -c \"printf 'if [[ -z \\\$DISPLAY && \\\$(tty) == /dev/tty1 ]]; then\\nexec start-hyprland &>/dev/null\\nfi' > /home/$username/.bash_profile\"" || {
    notice "Failed to setup hyprland to auto start"
  }
}

load_configs() {
  local default_git_link="https://github.com/amanuel0101/dots.git"
  style 1 "Creating .config..."
  arch-chroot /mnt su "$username" -c "mkdir -p /home/$username/.config" || return 1
  style 1 "Downloading configs..."
  arch-chroot /mnt su "$username" -c "git clone $default_git_link /home/$username/.config/dots" || return 1
  style 1 "Loading configs..."
  arch-chroot /mnt su "$username" -c "cp -a /home/$username/.config/dots/. /home/$username/.config/" || return 1
  # quickshell
}

install_arch() {
  if ! $READY_TO_INSTALL; then
    gum style --foreground 1 "not ready to install!"
    return 1
  fi

  clear_logo
  gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Installing arch..."
  echo

  # partitioning
  partition_disk || return 1

  # mount
  mount_disk || return 1

  # detect and mout EFI
  setup_efi_partition || return 1

  # pacstrap
  install_base || return 1

  # fstab
  gen_fstab || return 1

  # arch-chroot
  run_arch_chroot || return 1

  # install extras
  install_extras || return 1

  # boot
  post_config

  load_configs
  if gum confirm --negative "Later" "Reboot now?"; then
    reboot now
  fi
}

handle_exit() {
  # umount disk/part
  gum style --foreground 4 --padding "0 0 0 $PADDING_LEFT" "Umountting..."
  umount -R /mnt || return 1
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

}

if ! start_install; then
  exit 1
fi

dis() {
  echo $username
  echo $password
  echo $hostname
  echo $timezone
  echo $install_disk
  echo $install_mode
  echo $install_partition
}

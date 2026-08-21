#!/usr/bin/env bash

set -e

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

LOGO_PATH="$HOME/logo.txt"
LOGO_WIDTH=$(awk '{ if (length > max) max = length } END { print max+0 }' "$LOGO_PATH")

OMARCHY_USERNAME_PATTERN='^[a-z_][a-z0-9_-]*[$]?$'
OMARCHY_RESERVED_USERNAMES='^(root|bin|daemon|mail|ftp|http|nobody|dbus|systemd-coredump|systemd-network|systemd-oom|systemd-journal-remote|systemd-resolve|systemd-timesync|tss|uuidd|alpm|git|avahi|cups|lp|_talkd|polkitd|rtkit|qemu|brltty|gluster|rpc|libvirt-qemu|pcscd|nvidia-persistenced|sddm)$'
OMARCHY_HOSTNAME_PATTERN='^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
OMARCHY_HOSTNAME_DEFAULT='arch'

export GUM_CONFIRM_PROMPT_FOREGROUND="6"
export GUM_CONFIRM_SELECTED_FOREGROUND="0"
export GUM_CONFIRM_SELECTED_BACKGROUND="2"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="7"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="0"

PURPLE="57"
PINK="212"

ready_to_install=false
user_form_confirmed=false
disk_form_confirmed=false

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
  gum spin --spinner "pulse" --title "$1" -- sleep "${2:-2}"
}

set_tty_colors_back() {
  printf '\e]P0000000'
  printf '\e]P1AA0000'
  printf '\e]P200AA00'
  printf '\e]P3AA5500'
  printf '\e]P40000AA'
  printf '\e]P5AA00AA'
  printf '\e]P600AAAA'
  printf '\e]P7AAAAAA'
  printf '\e]P8555555'
  printf '\e]P9FF5555'
  printf '\e]PA55FF55'
  printf '\e]PBFFFF55'
  printf '\e]PC5555FF'
  printf '\e]PDFF55FF'
  printf '\e]PE55FFFF'
  printf '\e]PFFFFFFF'
  printf '\e[0m\e[2J\e[H'
}

set_tokyo_night_colors() {
  echo -en "\e]P01a1b26"
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

omarchy_username_taken() { return 1; }

omarchy_prompt_username() {
  local status
  while true; do
    username=$(gum input --placeholder "Alphanumeric without spaces (like abebe)" --prompt.foreground="$PURPLE" --prompt "Username> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ "$username" =~ $OMARCHY_USERNAME_PATTERN ]]; then
      if [[ "$username" =~ $OMARCHY_RESERVED_USERNAMES ]]; then
        notice "Username is reserved for system" 1
      elif omarchy_username_taken "$username"; then
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

omarchy_prompt_password() {
  local status
  while true; do
    password=$(gum input --placeholder "Used for user + root, and disk encryption when enabled" --prompt.foreground="$PURPLE" --password --prompt "Password> ") && status=0 || status=$?
    ((status == 0)) || return $status
    password_confirmation=$(gum input --placeholder "Must match the password you just typed" --prompt.foreground="$PURPLE" --password --prompt "Confirm> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ -n "$password" && "$password" == "$password_confirmation" ]]; then
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

omarchy_prompt_hostname() {
  local status
  while true; do
    hostname=$(gum input --placeholder "Letters, digits, and dashes (or return for '$OMARCHY_HOSTNAME_DEFAULT')" --prompt.foreground="$PURPLE" --prompt "Hostname> ") && status=0 || status=$?
    ((status == 0)) || return $status

    if [[ -z $hostname ]]; then
      hostname="$OMARCHY_HOSTNAME_DEFAULT"
      return 0
    elif [[ "$hostname" =~ $OMARCHY_HOSTNAME_PATTERN ]]; then
      return 0
    else
      notice "Hostname must be 1-63 letters, digits, or dashes, and cannot start or end with a dash" 1
    fi
  done
}

# ---------------------------------------------------------
# timezone
# ---------------------------------------------------------

omarchy_prompt_timezone() {
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
Password,$(printf "%${#password}s" | tr ' ' '*')
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
    omarchy_prompt_username
    omarchy_prompt_password
    omarchy_prompt_hostname
    omarchy_prompt_timezone

    if confirm_user_form; then
      user_form_confirmed=true
      clear_logo
      break
    fi
  done
}

# ---------------------------------------------------------
# disk
# ---------------------------------------------------------

disk_form1() {
  step "Let's select where to install Omarchy..."

  # Don't offer the install media as an option (Arch ISO mounts it here)
  local boot_source
  local exclude_disk
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

  selected_display=$(echo "$disk_options" | gum choose --header "Select install disk") || abort
  disk=$(echo "$selected_display" | awk '{print $1}')
}

install_mode_form() {
  local choices=("Full disk install")

  # The free-space/protected path registers an EFI boot entry and is UEFI-only.
  if [[ -d /sys/firmware/efi ]] && ! $full_disk_only; then
    choices+=("Free space install (alongside existing data)")
  fi
  choices+=("Choose a different disk")

  step "Let's select how to install Omarchy..."
  install_mode=$(gum choose --header "Select installation mode on $disk" "${choices[@]}") || abort
}

FREE_SPACE_INFO=$(parted -ms "$disk" unit B print free </dev/null 2>/dev/null |
  awk -F: '
    $NF ~ /free/ {
      start=$2; end=$3; size=$4;
      gsub(/B/, "", start); gsub(/B/, "", end); gsub(/B/, "", size);
      if (size+0 > max_size+0) { max_size=size; max_start=start; max_end=end; }
    }
    END { if (max_size+0 > 0) printf "%s %s %s\n", max_start, max_end, max_size; }')

#select_install_disk() {
#  local disks
#  local selected
#  local disk_name
#
#  disks=$(lsblk -dn -o NAME \
#    -e 7,11 \
#    2>/dev/null)
#
#  if [[ -z "$disks" ]]; then
#    gum style \
#      --foreground 1 \
#      "No installation disks were found."
#
#    return 1
#  fi
#
#  local options=()
#
#  while IFS= read -r disk_name; do
#    [[ -z "$disk_name" ]] && continue
#
#    local disk_path="/dev/$disk_name"
#    local size vendor model
#    local info
#    local partitions
#
#    size=$(lsblk -dn -o SIZE "$disk_path")
#    vendor=$(lsblk -dn -o VENDOR "$disk_path" | xargs)
#    model=$(lsblk -dn -o MODEL "$disk_path" | xargs)
#
#    [[ -z "$vendor" ]] && vendor="Unknown vendor"
#    [[ -z "$model" ]] && model="Unknown model"
#
#    info="$disk_path  •  $size  •  $vendor $model"
#
#    partitions=$(lsblk \
#      -n \
#      -l \
#      -o NAME,SIZE,FSTYPE,MOUNTPOINTS \
#      "$disk_path" |
#      tail -n +2 |
#      sed 's/^/    /')
#
#    if [[ -n "$partitions" ]]; then
#      info+=$'\n'"$partitions"
#    else
#      info+=$'\n'"    No partitions"
#    fi
#
#    options+=("$info")
#
#  done <<<"$disks"
#
#  selected=$(printf '%s\n' "${options[@]}" | gum choose \
#    --header "Select install disk" \
#    --height 15 \
#    --header.foreground=4)
#
#  [[ -n "$selected" ]] || return 1
#
#  # Extract /dev/... from the selected entry
#  install_disk=$(printf '%s\n' "$selected" | head -n 1 | awk '{print $1}')
#
#  return 0
#}
#
#select_install_disk

select_install_disk() {
  local selected

  selected=$(lsblk -dpno NAME,SIZE,MODEL -e 7,11 | gum choose --header "Installation Disk" --height 10) || return 1

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
  esac
}

select_install_partition() {
  local selected

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
  esac

  echo "$(
    printf '%s\n' \
      'Field, Value' \
      "Disk,$install_disk" \
      "Mode,$mode" \
      "$(if [[ "$install_mode" == "partition" ]]; then
        printf 'Partition,%s' "$install_partition"
      fi)"
  )" |
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
    select_install_disk
    choose_disk_mode
    if [[ "$install_mode" == "partition" ]]; then
      select_install_partition
    fi

    if confirm_disk_form; then
      disk_form_confirmed=true
      clear_logo
      break
    fi
  done
}

confirm_installation() {
  while true; do
    if ! $user_form_confirmed; then
      notice "Fill the user form!"
      user_form
      continue
    fi

    if ! $disk_form_confirmed; then
      notice "Fill the disk form!"
      disk_form
      continue
    fi

    local prompt
    local affirm
    if [[ "$install_mode" == "disk" ]]; then
      prompt="Everything on $install_disk will be overwritten. Are you sure you want to install?"
      affirm="Yes, format disk and install"
    else
      prompt="Partition $install_partition will be overwritten. Do you want to install?"
      affirm="Yes, install"
    fi

    if gum confirm --affirmative "$affirm" --negative "No, change it" "$prompt"; then
      ready_to_install=true
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

partition_disk() {

  if [[ "$install_mode" == "disk" ]]; then
    notice "Full disk install not available yet"
    return 1
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

    return 0
  else
    clear_logo
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Invalid installation mode: '$install_mode'"
    return 1
  fi
}

mount_disk() {
  mkdir -p /mnt || {
    gum style --foreground 1 "Failed to create /mnt."
    return 1
  }

  spin "Mounting $root_partition..." "mount $root_partition /mnt" || {
    gum style --foreground 1 "Failed to mount $root_partition."
    return 1
  }
}

detect_mount_efi() {
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
  pacman -Sy || {
    gum style --foreground 1 "Failed to sync pacman."
    return 1
  }

  pacman-key --init || {
    gum style --foreground 1 "Failed to initialize pacman keyring."
    return 1
  }

  pacstrap -K --config /etc/pacman.conf /mnt base linux linux-firmware networkmanager hyprland || {
    gum style --foreground 1 "Failed to install the base system."
    return 1
  }

  notice "base system install complete."
}

install_arch() {
  # if ! $ready_to_install; then
  #   gum style --foreground 1 "not ready to install!"
  #   return 1
  # fi
  #

  clear_logo
  gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Installing arch..."
  echo

  # partitioning
  if ! partition_disk; then
    return 1
  fi

  # mount
  if ! mount_disk; then
    return 1
  fi

  # detect and mout EFI
  if ! detect_mount_efi; then
    return 1
  fi

  # pacstrap
  if ! install_base; then
    return 1
  fi
}

start_install() {
  user_form
  disk_form
  confirm_installation
  install_arch
}

start_install

dis() {
  echo $username
  echo $password
  echo $hostname
  echo $timezone
  echo $install_disk
  echo $install_mode
  echo $install_partition
}

: <<'DISABLE'
# ---------------------------------------------------------
# Welcome
# ---------------------------------------------------------

clear_screen
header "Welcome to the $DISTRO_NAME installer"

echo

gum style \
  --align center \
  "Let's get your system installed."

echo

if gum confirm "Continue with installation?"; then
  :
else
  clear_screen
  exit 0
fi

# ---------------------------------------------------------
# Installation
# ---------------------------------------------------------

clear_screen

header "Installation"

echo

gum style \
  --align center \
  "The installer is ready."

echo

gum spin \
  --spinner dot \
  --title "Preparing installation..." \
  -- sleep 2

clear_screen

gum style \
  --border double \
  --padding "2 6" \
  --align center \
  "$DISTRO_NAME" \
  "" \
  "Installation setup complete."

echo
DISABLE

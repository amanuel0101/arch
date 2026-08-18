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
  gum style --foreground "#8A9A7B" --padding "1 0 0 $PADDING_LEFT" "$(<"$LOGO_PATH")"
  echo
}

notice() {
  clear_logo
  gum spin --spinner "pulse" --title "$1" -- sleep "${2:-2}"
}

# ---------------------------------------------------------
# Username
# ---------------------------------------------------------

clear_logo

omarchy_prompt_username() {
  local status

  while true; do
    username=$(gum input \
      --placeholder "Enter your username" \
      --prompt.foreground="#795DCE" \
      --prompt "Username> ") && status=0 || status=$?

    ((status == 0)) || return $status

    if [[ "$username" =~ ^[a-zA-Z0-9]+$ ]]; then
      return 0
    else
      notice "Username must be alphanumeric with no spaces" 1
    fi
  done
}

omarchy_prompt_username

# ---------------------------------------------------------
# Password
# ---------------------------------------------------------

omarchy_prompt_password() {
  local status

  while true; do
    password=$(gum input \
      --placeholder "Used for user + root, and disk encryption when enabled" \
      --prompt.foreground="#795DCE" \
      --password \
      --prompt "Password> ") && status=0 || status=$?

    ((status == 0)) || return $status

    password_confirmation=$(gum input \
      --placeholder "Must match the password you just typed" \
      --prompt.foreground="#795DCE" \
      --password \
      --prompt "Confirm> ") && status=0 || status=$?

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

omarchy_prompt_password

# ---------------------------------------------------------
# hostname
# ---------------------------------------------------------

omarchy_prompt_hostname() {
  local status
  while true; do
    hostname=$(gum input --placeholder "Letters, digits, and dashes (or return for 'arch')" --prompt.foreground="#795DCE" --prompt "Hostname> ") && status=0 || status=$?
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

omarchy_prompt_hostname

# ---------------------------------------------------------
# timezone
# ---------------------------------------------------------

omarchy_prompt_timezone() {
  local guess status
  guess=$(curl -fsS 'http://ip-api.com/line?fields=timezone' 2>/dev/null) || guess=""

  if [[ -n $guess ]]; then
    timezone=$(timedatectl list-timezones | gum choose --height 10 --selected "$guess" --header "Timezone" --header.foreground="#795DCE") && status=0 || status=$?
  else
    timezone=$(timedatectl list-timezones | gum filter --height 10 --header "Timezone" --header.foreground="#795DCE") && status=0 || status=$?
  fi
  ((status == 0)) || return $status

  [[ -n $timezone ]] || timezone="UTC"
}

omarchy_prompt_timezone

# ---------------------------------------------------------
# disk
# ---------------------------------------------------------

disk_form() {
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
#    --header.foreground="#795DCE")
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

  selected=$(lsblk -dpno NAME,SIZE,MODEL -e 7,11 |
    gum choose \
      --header "Installation Disk" \
      --header.foreground="#795DCE" \
      --height 10) || return 1

  install_disk=$(awk '{print $1}' <<<"$selected")

  [[ -b "$install_disk" ]]
}

select_install_disk

choose_disk_mode() {
  local choice

  choice=$(printf '%s\n' \
    "Use entire disk" \
    "Select a partition" |
    gum choose \
      --header "How do you want to install?" \
      --header.foreground="#795DCE") || return 1

  case "$choice" in
  "Use entire disk")
    install_mode="disk"
    ;;

  "Select a partition")
    install_mode="partition"
    ;;
  esac
}

choose_disk_mode

select_install_partition() {
  local selected

  while true; do
    selected=$(
      {
        lsblk -n "$install_disk"
        printf '%s\n' "Create a new partition"
      } |
        gum choose \
          --header "Select Installation Partition" \
          --header.foreground="#795DCE" \
          --height 12
    ) || return 1

    if [[ "$selected" == "Create a new partition" ]]; then
      if ! cfdisk "$install_disk"; then
        gum style --foreground="#795DCE" \
          "You can run the installer again with: ~/installer.sh"
        return 1
      fi
      continue
    fi

    install_partition=$(sed -E 's/^[^a-zA-Z0-9]*//' <<<"$selected" | awk '{print $1}')
    install_partition="/dev/$install_partition"

    if [[ -b "$install_partition" ]]; then
      return 0
    fi
  done
}

if [[ "$install_mode" == "partition" ]]; then
  select_install_partition
fi

echo $username
echo $password
echo $hostname
echo $timezone
echo $install_disk
echo $install_mode
echo $install_partition
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

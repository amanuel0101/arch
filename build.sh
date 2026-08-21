#!/bin/bash
set -e

PROFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

# What to install on the target
TARGET_PKGS=$(grep -hv '^#\|^$' "$PROFILE_DIR/target-packages.txt")

# Download into airootfs so mkarchiso includes them
CACHE_DIR="$PROFILE_DIR/airootfs/var/cache/offline-mirror/pkg"
mkdir -p "$CACHE_DIR"

mkdir -p /tmp/offlinedb

# Use your existing pacman.conf (online) to fetch packages
pacman --config pacman.conf --noconfirm -Syw \
  $TARGET_PKGS \
  --cachedir "$CACHE_DIR" \
  --dbpath /tmp/offlinedb \
  --needed

# Build the repo index
repo-add "$CACHE_DIR/offline.db.tar.gz" "$CACHE_DIR/"*.pkg.tar.zst

# Count expected packages for progress bar
#echo "$TARGET_PKGS" | wc -w >"airootfs/usr/share/my-distro/expected-packages"

rm -rf "$PROFILE_DIR"/work
mkarchiso -v -w "$PROFILE_DIR/work" -o "$PROFILE_DIR/out" "$PROFILE_DIR"
notify-send "InFo" "DONE!!!"

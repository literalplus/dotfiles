#!/usr/bin/env bash
set -e

# shellcheck source=lib.sh
source ../lib.sh

if [ -n "$DRY_RUN" ]; then
  pnot "Doing a dry run."
else
  pwrn "Writing to LIVE mirrorlist."
fi

if [ "$(id -u)" -ne 0 ]; then
  perr "We need root for this!"
  exit 1
fi

psec "Mirrorlist setup"

MIRRORS_TARGET="/etc/pacman.d/mirrorlist"
MIRRORS_BEFORE="/etc/pacman.d/mirrorlist.beforerank"
MIRRORS_AFTER="/etc/pacman.d/mirrorlist.ranked"
MIRRORS_BACKUP="/etc/pacman.d/mirrorlist.backup_$(date +"%Y-%M-%d_%H%m")"

pnot "Creating mirrorlist backup $MIRRORS_BACKUP"
cp "$MIRRORS_TARGET" "$MIRRORS_BACKUP"

if [ -n "$DRY_RUN" ]; then
  cp /etc/pacman.d/mirrorlist /tmp/mirrorlist
  MIRRORS_TARGET="/tmp/mirrorlist"
fi
pnot "Target file is $MIRRORS_TARGET"

pnot "Writing upstream mirrorlist to $MIRRORS_BEFORE"
curl -s "https://archlinux.org/mirrorlist/?country=AT&country=CZ&country=DE&country=SK&country=SI&protocol=https&ip_version=4&use_mirror_status=on" >"$MIRRORS_BEFORE"

sed -i 's/^#Server/Server/' "$MIRRORS_BEFORE"

pnot "Now ranking mirrors..."
rankmirrors -n 6 "$MIRRORS_BEFORE" > "$MIRRORS_AFTER"

pnot "Mirrorlist will be:"
dim
cat "$MIRRORS_TARGET"
undim

confirmbefore cp "$MIRRORS_AFTER" "$MIRRORS_TARGET"

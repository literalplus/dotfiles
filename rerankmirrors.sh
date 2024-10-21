#!/usr/bin/env bash
source ./lib.sh

if [ "$(id -u)" -ne 0 ]; then
  perr "We need root for this!"
  exit 1
fi

psec "Preparation"
MIRRORS="/etc/pacman.d/mirrorlist"
TODAY="$(date +'%Y-%m-%d')"
MIRRORSWAP="$MIRRORS.rank_$TODAY"
MIRRORBKP="$MIRRORS.bkp_$TODAY"

curl -s "https://archlinux.org/mirrorlist/?country=AT&country=CZ&country=DE&country=SK&country=SI&protocol=https&ip_version=4&use_mirror_status=on" >"$MIRRORSWAP"
cp "$MIRRORS" "$MIRRORBKP"
pnot "Mirror list backup placed at $MIRRORBKP"
pnot "List-to-rank is at $MIRRORSWAP"
sed -i 's/^#Server/Server/' "$MIRRORSWAP"
confirmbefore_unsafe_eval rankmirrors -n 6 "$MIRRORSWAP" \> "$MIRRORS"
dim
grep -v "#" < "$MIRRORS"
undim

pnot "Done."


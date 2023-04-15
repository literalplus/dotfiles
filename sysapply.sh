#!/usr/bin/env bash
source lib.sh

if [ "$(id -u)" -eq 0 ]; then
  perr This script should not be run as root.
  exit 1
fi

psec "Installing standard scripts to /usr/local/bin"
pushd scripts >/dev/null || exit
for script in *; do
  sudo bash -c "source $PWD/../lib.sh && applycp \"$script\" \"/usr/local/bin/$script\" overwrite"
done
popd >/dev/null || exit

psec "Installing standard systemd unit files"
pushd systemd >/dev/null || exit
for unit in *; do
  sudo bash -c "source $PWD/../lib.sh && applycp \"$unit\" \"/etc/systemd/system/$unit\" overwrite"
done
confirmbefore sudo systemctl daemon-reload
psec "Enabling installed unit files"
for unit in *; do
  sudo systemctl enable "$unit"
done
popd >/dev/null || exit

psec "Setting up etckeeper"
if [[ ! -d /etc/.git ]]; then
  pnot "No /etc/.git - Proceeding with setup."
  pushd /etc >/dev/null || exit
  destcmd yay -Sy etckeeper
  confirmbefore sudo etckeeper init
  HOSTN="$(hostname 2>/dev/null || hostnamectl hostname 2>/dev/null || echo unknown)"
  destcmd sudo git config --local user.name "$HOSTN etckeeper"
  destcmd sudo git config --local user.email "$HOSTN-etckeeper@lit.plus"
  destcmd sudo etckeeper commit "Initial commit from sysapply.sh"
  popd >/dev/null || exit
else
  pnot "Looks like it's already set up."
fi
sudo systemctl enable etckeeper.timer

psec "Making sure yay is installed"
confirmbefore sudo pacman -Syu
if which yay >/dev/null; then
  pnot "Already installed"
else
  pushd build || exit
  git clone https://aur.archlinux.org/yay.git
  pushd yay || exit
  makepkg -si
  popd || exit
  rm -r yay
  popd || exit
fi

function yayfromfile () {
  FILECAT=$1
  yay -S --color=always --needed "$(tr "\n" " " < "$FILECAT/packages") 2>&1 | grep -v --color=always "is up to date -- skipping"
}

psec "Base packages"
yayfromfile base

psec "Code packages"
yayfromfile code

if [ "$PERSONAL" -eq 0 ]; then
  psec "Personal packages"
  yayfromfile personal
fi

psec "Workarounds"
# none atm !

psec "Emoji Fonts"
applycp "base/75-noto-color-emoji.conf" "/etc/fonts/conf.avail/75-noto-color-emoji.conf"
sudo ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
sudo ln -sf /etc/fonts/conf.avail/75-noto-color-emoji.conf /etc/fonts/conf.d/


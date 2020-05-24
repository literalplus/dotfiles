#!/usr/bin/env bash
source lib.sh

if [ "$(id -u)" -eq 0 ]; then
  perr This script should not be run as root.
  exit 1
fi

pushd scripts >/dev/null
for script in *; do
  sudo bash -c "source $PWD/../lib.sh && applycp \"$script\" \"/usr/local/bin/$script\" overwrite"
done
popd >/dev/null

psec "Making sure yay is installed"
sudo pacman -Syu
if which yay >/dev/null; then
  pnot "Already installed"
else
  pushd build
  git clone https://aur.archlinux.org/yay.git
  pushd yay
  makepkg -si
  popd
  rm -r yay
  popd
fi

function yayfromfile () {
  FILECAT=$1
  yay -S --color=always --needed $(cat $FILECAT/packages | tr "\n" " ") 2>&1 | grep -v --color=always "is up to date -- skipping"
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
pnot "Disabling starting pulseaudio via systemd, it ships xdg files anyways"
# Also we don't need a screenreader on the login screen, gdm plsno as well
# If we don't do this, PA seems to block in uninterruptible sleep forever
sudo ln -s /dev/null /var/lib/gdm/.config/systemd/user/pulseaudio.service
systemctl --user disable pulseaudio

#!/usr/bin/env bash
source lib.sh

if [ "$(id -u)" -eq 0 ]; then
  perr This script should not be run as root.
  exit 1
fi

psec "Installing standard scripts to /usr/local/bin"
pushd scripts >/dev/null || exit
for script in *; do
  if ! [[ -f $script ]]; then
    continue
  fi
  sudo bash -c "source $PWD/../lib.sh && applycp \"$script\" \"/usr/local/bin/$script\" overwrite"
done

psec "Installing standard Albert plugins to /usr/share/albert/python/plugins"
pushd albert-python >/dev/null || exit

for plugin in *; do
  if [[ $plugin =~ (.*).py ]]; then
    rawname=${BASH_REMATCH[1]}
    target="/usr/share/albert/python/plugins/$rawname"
    sudo mkdir -p "$target"
    sudo bash -c "source $PWD/../../lib.sh && applycp \"$plugin\" \"$target/__init__.py\" overwrite"
  fi
done

popd >/dev/null || exit
popd >/dev/null || exit

psec "Installing standard systemd unit files"
pushd systemd >/dev/null || exit
for unit in *; do
  sudo bash -c "source $PWD/../lib.sh && applycp \"$unit\" \"/etc/systemd/system/$unit\" overwrite"
done
confirmbefore sudo systemctl daemon-reload
psec "Enabling installed unit files"
for unit in *; do
  if [[ "$unit" != *"@.service" ]]; then
    sudo systemctl enable "$unit"
  fi
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
  # Word splitting is intended here, each package is a separate
  # argument.
  # shellcheck disable=SC2046
  yay -S --color=always --needed $(tr "\n" " " < "$FILECAT/packages") 2>&1
}

psec "Base packages"
confirmbefore yayfromfile base

pnot "fail2ban sshd config"
F2B_CONF_NAME="fail2ban-sshd-dotfiles.conf"
sudo bash -c "source $PWD/lib.sh && applycp \"base/$F2B_CONF_NAME\" \"/etc/fail2ban/jail.d/$F2B_CONF_NAME\" overwrite"
sudo systemctl enable fail2ban

pnot "Enable pacman cache cleanup"
sudo systemctl enable paccache.timer

psec "Code packages"
confirmbefore yayfromfile code

if [ "$PERSONAL" -eq 0 ]; then
  psec "Personal packages"
  confirmbefore yayfromfile personal
fi

psec "Firewall (nftables)"
sudo bash -c "source $PWD/lib.sh && applycp installation/nftables.conf /etc/nftables.conf"

psec "Workarounds"
# none atm !

psec "Emoji Fonts"
applycp "base/75-noto-color-emoji.conf" "/etc/fonts/conf.avail/75-noto-color-emoji.conf"
sudo ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
sudo ln -sf /etc/fonts/conf.avail/75-noto-color-emoji.conf /etc/fonts/conf.d/


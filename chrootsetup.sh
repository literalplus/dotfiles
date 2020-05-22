#!/usr/bin/env bash
if [ -d /dotfiles ]; then
  cd /dotfiles
fi

source lib.sh

if [ -z "$DRY_RUN" ]; then
  pwrn "NOT doing a dry run!"
elif [ -n "$DRY_RUN" ]; then
  pnot "Doing a dry run! :)"
else
  perr "Doing a dry run but also not. lol"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  perr "We need root for this!"
  exit 1
fi

if [ -z "$TMUX" ]; then
  pwrn "It is required to run the setup in tmux!"
  exit 1
fi

psec "Configure the system (inside chroot)"
destcmd ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
destcmd timedatectl set-ntp true
destcmd hwclock --systohc
destcmd sed -i 's/^#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen
destcmd echo "LANG=en_GB.UTF-8" \>/etc/locale.gen
destcmd locale-gen
destcmd echo "KEYMAP=de-latin1-nodeadkeys" \>/etc/vconsole.conf

if [ -f /etc/hostname ]; then
  pnot "Hostname already set."
else
  pask "What is the hostname of this system?"
  read hn
  pnot "Setting hostname to $hn"
  destcmd echo "$hn" \>/etc/hostname
  destcmd echo "127.0.0.1 localhost" \>/etc/hosts
  destcmd echo "::1 localhost" \>\>/etc/hosts
  destcmd echo "127.0.1.1 $hn" \>\>/etc/hosts
fi

confirmbefore systemctl disable systemd-networkd.service \
  \&\& systemctl disable systemd-resolved.service \
  \&\& pacman -Sy --needed networkmanager

psec "Setting up user account"
pask "Setting up sudo for wheel group"
TMP_SUDOERS=$(mktemp)
cp /etc/sudoers "$TMP_SUDOERS"
sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' "$TMP_SUDOERS"
if ! visudo -c -f "$TMP_SUDOERS"; then
  perr "Modified sudoers file not longer validates."
  exit 1
fi
destcmd cp /etc/sudoers /etc/sudoers.bkp
destcmd mv "$TMP_SUDOERS" /etc/sudoers
pask "What is the primary username for this system?"
read un
if ! id $un; then
  pnot "Setting up user account for $un"
  destcmd useradd -m -s /usr/bin/zsh -G sys,wheel "$un"
  pask "Please specify password for $un"
  destcmd passwd "$un"
fi
psec "Making sure yay is installed"
if which yay >/dev/null; then
  pnot "yay is installed"
else
  mkdir -p build
  chown -R pnowak: build
  pushd build
  sudo -u "$un" git clone https://aur.archlinux.org/yay.git
  pushd yay
  sudo -u "$un" makepkg -si
  popd
  rm -r yay
  popd
fi


psec "Boot loader (Part I)"
confirmbefore bootctl install \
  \&\& sudo -u "$un" yay -Sy --needed systemd-boot-pacman-hook

psec "Encryption setup"
echo "Please now configure mkinitcpio for encryption."
pwrn "Do NOT include the stars. These mark what you need to add!"
echo "HOOKS=(base *systemd autodetect *keyboard *sd-vconsole modconf block *sd-encrypt filesystems fsck)"
tmux split-window vim /etc/mkinitcpio.conf
confirmbefore cat /etc/mkinitcpio.conf \| grep HOOKS

KPARAMS="rd.luks.name=$ROOT_PARTID=cryptroot"
pnot "Kernel parameters: $KPARAMS"
pask "Please add these to the kernel line! (options ...)"
tmux split-window vim /boot/loader/entries/arch.conf
confirmbefore cat /boot/loader/entries/arch.conf \| grep options
confirmbefore mkinitcpio -P

psec "User accounts (Part II)"
pask "Please set a strong root password."
destcmd passwd root

psec "Boot loader (Part II)"
pask "Please edit the boot loader configuration."
pnot "Recommended: Set editor=no to prevent setting kernel line to /bin/bash"
pnot "default should be arch.conf"
tmux split-window vim /boot/loader/loader.conf
confirmbefore cat /boot/loader/loader.conf

psec "Firewall"
cp /dotfiles/nftables.conf /etc/nftables.conf
destcmd systemctl enable nftables
destcmd systemctl start nftables


#pask "If this is an Intel system, install microcode."
#pnot "Add a line 'initrd /cpu_intel-ucode.img' before"
#pnot "'initrd /initramfs-linux.img'."
#confirmbefore pacman -S intel-ucode \
#  \&\& tmux split-window /boot/loader/entries/arch.conf

psec "Exit chroot"


# TODO https://wiki.archlinux.org/index.php/Installation_guide
# TODO https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption

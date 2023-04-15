#!/usr/bin/env bash
if [ -d /dotfiles ]; then
  cd /dotfiles || exit
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


if [ -f /etc/hostname ]; then
  hn="$(cat /etc/hostname)"
  pnot "Hostname already set to $hn"
else
  pask "What is the hostname of this system?"
  read -r hn
  pnot "Setting hostname to $hn"
fi

destcmd sed -i 's/^#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen
destcmd locale-gen

destcmd systemd-firstboot \
  --locale=en_GB.UTF-8 \
  --keymap=de-latin1-nodeadkeys \
  --timezone=Europe/Vienna \
  "--hostname=$hn" \
  --setup-machine-id \
  --root=/

# ref: https://github.com/systemd/systemd/issues/798 (this is the same as set-ntp)
destcmd systemctl enable systemd-timesyncd
destcmd hwclock --systohc


# Not disabling systemd-resolved -> resolvectl for VPN up/down scripts
# stub-resolv.conf is configured outside the chroot as per the wiki
confirmbefore_unsafe_eval systemctl disable systemd-networkd.service \
  \&\& pacman -Sy --needed networkmanager \
  \&\& systemctl enable NetworkManager

psec "Setting up user account"
pask "Setting up sudo for wheel group"
TMP_SUDOERS=$(mktemp)
cp /etc/sudoers "$TMP_SUDOERS"
sed -i -e 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$TMP_SUDOERS"
if ! visudo -c -f "$TMP_SUDOERS"; then
  perr "Modified sudoers file not longer validates."
  exit 1
fi
destcmd cp /etc/sudoers /etc/sudoers.bkp
destcmd mv "$TMP_SUDOERS" /etc/sudoers
pask "What is the primary username for this system?"
read -r un
if ! id "$un"; then
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
  chown -R "$un"":" build
  pushd build || exit
  sudo -u "$un" git clone https://aur.archlinux.org/yay.git
  pushd yay || exit
  sudo -u "$un" makepkg -si
  popd || exit
  rm -r yay
  popd || exit
fi

psec "Encryption setup"
echo "Please now configure mkinitcpio for encryption."
pwrn "Do NOT include the stars. These mark what you need to add!"
pnot "Move the keyboard hook before autodetect to include all keyboard drivers in the initramfs."
pnot "Add sd-vconsole and sd-encrypt (in that order)"
pnot "Replace keymap and consolefont with sd-vconsole"
pnot "Replace udev with systemd"
echo "HOOKS=(base *systemd *keyboard autodetect modconf kms *sd-vconsole block *sd-encrypt filesystems fsck)"
tmux split-window vim /etc/mkinitcpio.conf
confirmbefore grep HOOKS /etc/mkinitcpio.conf

psec "Boot loader"
pwrn "This only works on Intel systems! Adapt loader.conf for AMD"
destcmd pacman -Sy --needed intel-ucode
destcmd sudo -u "$un" yay -Sy --needed systemd-boot-pacman-hook

pask "Please select whether to use SecureBoot: (yes/no)"
read -r secboo

if [ "$secboo" = "yes" ]; then
  psuc "Ok, using Secure Boot"
  # assume that systemd-boot-pacman-hook uses 95
  destcmd cp /dotfiles/96-bootctl-copy-loader.hook /usr/share/libalpm/hooks/96-bootctl-copy-loader.hook
  destcmd sudo -u "$un" yay -Sy --needed preloader-signed
  destcmd cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi /boot/EFI/systemd
  confirmbefore bootctl install
  # sadly, PreLoader requires this exact name
  destcmd cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi
  confirmbefore efibootmgr --unicode --disk /dev/nvme0n1 --part 1 --create --label "PreLoader" --loader /EFI/systemd/PreLoader.efi
else
  psuc "Not using Secure Boot."
  confirmbefore bootctl install
fi

ALLDISKS=$(fdisk -l | grep /dev/ | grep "Linux filesystem" | grep -v "Disk /dev/")
if ! ROOT_PART=$(echo "$ALLDISKS" | fzf --header="Encrypted root partition (again)"); then
  perr "Aborted."
  exit 1
else
  ROOT_PART=$(echo "$ROOT_PART" | awk '{print $1}')
  psuc "Encrypted root partition: $ROOT_PART"
  ROOT_PARTID=$(blkid "$ROOT_PART" -s UUID -o value)
  pask "Found UUID: $ROOT_PARTID (y/N)"
  exitifnok
fi

KPARAMS="root=/dev/mapper/cryptroot rootfstype=ext4 add_efi_memmap rd.luks.name=$ROOT_PARTID=cryptroot"
pask "Kernel line: $KPARAMS (y/N)"
exitifnok
# KPARAMS cannot be quoted, quotes are literally inserted into the file
# shellcheck disable=SC2086
cat >/tmp/loader-entry.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
options $KPARAMS
EOF

dim
cat /tmp/loader-entry.conf
undim
destcmd mv /tmp/loader-entry.conf /boot/loader/entries/arch.conf

confirmbefore cat /boot/loader/loader.conf
confirmbefore mkinitcpio -P

psec "User accounts (Part II)"
pask "Please set a strong root password."
destcmd passwd root
pask "Setting up zsh config"
sudo -u "$un" -i sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo -u "$un" -i git clone https://github.com/literalplus/dotfiles
cp /dotfiles/zshrc-tpl "/home/$un/.zshrc"


psec "Firewall"
cp /dotfiles/nftables.conf /etc/nftables.conf
destcmd systemctl enable nftables
destcmd systemctl start nftables

psec "GUI"
destcmd pacman -Sy gnome
destcmd pacman -Sy pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

psec "Exit chroot"


# TODO https://wiki.archlinux.org/index.php/Installation_guide
# TODO https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption

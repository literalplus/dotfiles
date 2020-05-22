#!/usr/bin/env bash
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

destcmd pacman -Sy --needed tmux

if [ -z "$TMUX" ]; then
  pwrn "It is required to run the setup in tmux!"
  exit 1
fi


psec "Environment setup"
destcmd loadkeys de-latin1-nodeadkeys

if [ ! -d /sys/firmware/efi/efivars ]; then
  pwrn "Not booted as EFI system!"
  exit 1
fi

dim
ip link
curl https://ifconfig.pro
undim
pask "Is the system connected to the internet? (y/N)"
exitifnok

pnot "Enabling NTP..."
destcmd timedatectl set-ntp true
pnot "Installing build dependencies..."
destcmd pacman -S --needed fzf pacman-contrib

psec "Partitioning the disks"
dim
fdisk -l
lsblk
undim
echo "Please partition the disks."
pnot "Recommended layout (gdisk):"
pnot " (1) 512M EFI system & boot partition EF00"
pnot " (2) remaining space 8300"
pnot " (3) 4G cryptswap placeholder (if needed) 8300"
pnot "If encrypting existing data, consider wiping the drives."
pnot "# gdisk /dev/sdX (Ctrl-D when done)"
pnot "Press n for a new partition, ? for help"
bash

pask "Continue? (y/N)"
exitifnok

ALLDISKS=$(fdisk -l | grep /dev/ | grep -v "Disk /dev/")
FZF_DEFAULT_OPTS="--reverse --height=10"
EFI_PART=$(echo "$ALLDISKS" | fzf --header="EFI system partition")
if [ "$?" -ne 0 ]; then
  perr "Aborted."
  exit 1
else
  EFI_PART=$(echo "$EFI_PART" | awk '{print $1}')
  psuc "EFI system partition: $EFI_PART"
fi

ROOT_PART=$(echo "$ALLDISKS" | fzf --header="Encrypted root partition")
if [ "$?" -ne 0 ]; then
  perr "Aborted."
  exit 1
else
  ROOT_PART=$(echo "$ROOT_PART" | awk '{print $1}')
  psuc "Encrypted root partition: $ROOT_PART"
  ROOT_PARTID=$(blkid "$ROOT_PART" -s PARTUUID -o value)
  pask "Found UUID: $ROOT_PARTID (y/N)"
  exitifnok
fi

SWAP_PART=$(echo "$ALLDISKS" | fzf --header="Encrypted swap partition")
if [ "$?" -ne 0 ]; then
  perr "Aborted."
  exit 1
else
  SWAP_PART=$(echo "$SWAP_PART" | awk '{print $1}')
  psuc "Encrypted swap partition: $SWAP_PART"
fi


psec "Format partitions"

confirmbefore mkfs.fat -F32 "$EFI_PART"
confirmbefore cryptsetup -y -v luksFormat "$ROOT_PART"
confirmbefore cryptsetup open "$ROOT_PART" cryptroot
confirmbefore mkfs.ext4 /dev/mapper/cryptroot
destcmd mkdir -p /mnt
confirmbefore mount /dev/mapper/cryptroot /mnt
destcmd mkdir -p /mnt/boot
confirmbefore mount "$EFI_PART" /mnt/boot

psec "Actual installation"
MIRRORS="/etc/pacman.d/mirrorlist"
if [ -n "$DRY_RUN" ]; then
  cp /etc/pacman.d/mirrorlist /tmp/mirrorlist
  MIRRORS="/tmp/mirrorlist"
fi
MIRRORSWAP="$MIRRORS.rankinstall"
cp "$MIRRORS" "$MIRRORS.backup"
curl -s "https://www.archlinux.org/mirrorlist/?country=AT&country=CZ&country=DE&country=SK&country=SI&protocol=https&ip_version=4&use_mirror_status=on" >"$MIRRORSWAP"
pnot "Mirror list backup placed at $MIRRORS.backup"
sed -i 's/^#Server/Server/' "$MIRRORSWAP"
confirmbefore rankmirrors -n 6 "$MIRRORSWAP" \> "$MIRRORS"
dim
cat "$MIRRORS"
undim

destcmd pacstrap /mnt base linux linux-firmware vim fzf zsh sudo which git nftables iptables-nft

psec "Configure the system"
destcmd genfstab -U /mnt \>\> /mnt/etc/fstab

destcmd mkdir -p /mnt/dotfiles
destcmd cp -r . /mnt/dotfiles
confirmbefore arch-chroot /mnt /dotfiles/chrootsetup.sh
destcmd rm -rf /mnt/dotfiles

psec "Reboot"
pnot "It is time to make broccoli!"
destcmd umount -R /mnt


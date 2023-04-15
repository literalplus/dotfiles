#!/usr/bin/env bash
source lib.sh

if [ "$(id -u)" -ne 0 ]; then
  perr "We need root for this!"
  exit 1
fi

destcmd pacman -Sy --needed tmux fzf pacman-contrib

if [ -z "$TMUX" ]; then
  pwrn "It is required to run the setup in tmux!"
  exit 1
fi

ALLDISKS=$(fdisk -l | grep /dev/ | grep -v "Disk /dev/")
export FZF_DEFAULT_OPTS="--reverse --height=10"

if ! EFI_PART=$(echo "$ALLDISKS" | fzf --header="EFI system partition"); then
  perr "Aborted."
  exit 1
else
  EFI_PART=$(echo "$EFI_PART" | awk '{print $1}')
  psuc "EFI system partition: $EFI_PART"
fi


if ! ROOT_PART=$(echo "$ALLDISKS" | fzf --header="Encrypted root partition"); then
  perr "Aborted."
  exit 1
else
  ROOT_PART=$(echo "$ROOT_PART" | awk '{print $1}')
  psuc "Encrypted root partition: $ROOT_PART"
  ROOT_PARTID=$(blkid "$ROOT_PART" -s PARTUUID -o value)
  pask "Found UUID: $ROOT_PARTID (y/N)"
  exitifnok
fi

confirmbefore cryptsetup open "$ROOT_PART" cryptroot
destcmd mkdir -p /mnt
confirmbefore mount /dev/mapper/cryptroot /mnt
destcmd mkdir -p /mnt/boot
confirmbefore mount "$EFI_PART" /mnt/boot

destcmd mkdir -p /mnt/dotfiles
destcmd cp -r . /mnt/dotfiles
# https://wiki.archlinux.org/title/Systemd-resolved#DNS -> cannot be done inside chroot (bind mount)
destcmd ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
psec "Run /dotfiles/chrootsetup.sh to continue setup in the chroot."
arch-chroot /mnt
destcmd rm -rf /mnt/dotfiles

psec "Reboot"
pnot "It is time to make broccoli!"
destcmd umount -R /mnt

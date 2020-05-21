#!/usr/bin/env bash
source lib.sh

if [ "$(id -u)" -ne 0 ]; then
  perr "We need root for this!"
  exit 1
fi

if [ -z "$TMUX" ]; then
  pwrn "It is recommended to run the setup in tmux!"
  pwrn "Really continue? (y/N)"
  exitifnok
fi


psec "Environment setup"
loadkeys de-latin1-nodeadkeys

if [ ! -d /sys/firmware/efi/efivars ]; then
  pwrn "Not booted as EFI system!"
  exit 1
fi

pask "Is the system connected to the internet? (y/N)"
dim
ip link
curl https://ifconfig.pro
undim
exitifnok

pnot "Enabling NTP..."
timedatectl set-ntp true

psec "Partitioning the disks"
dim
fdisk -l
undim
echo "Please partition the disks."
pnot "Recommended layout (gdisk):"
pnot " (1) 512M EFI system & boot partition EF00"
pnot " (2) remaining space 8300"
pnot " (3) 4G cryptswap placeholder (if needed) 8300"
pnot "# gdisk /dev/sdX (Ctrl-D when done)"
bash

psec "Format partitions"
echo "Please format the partitions."
pnot "Recommended setup:"
pnot " (1) mkfs.fat -F32 \$EFI_SYS"
pnot " todo"

# TODO https://wiki.archlinux.org/index.php/Installation_guide
# TODO https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
# TODO https://wiki.archlinux.org/index.php/Arch_boot_process#Boot_loader
# TODO https://wiki.archlinux.org/index.php/EFI_system_partition
# TODO https://wiki.archlinux.org/index.php/Microcode
# TODO https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption

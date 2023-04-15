#!/usr/bin/env bash
source lib.sh

if [ "$(id -u)" -eq 0 ]; then
  perr This script should not be run as root.
  exit 1
fi

psec Install drivers
destcmd yay -S --needed nvidia dkms linux-headers

psec Prevent noveau from loading
pwrn Please remove \"kms\" from the HOOKS array.

confirmbefore sudo vim /etc/mkinitcpio.conf
confirmbefore sudo mkinitcpio -P

psec Optimus - Use only NVIDIA
sudo bash -c "source $PWD/lib.sh && applycp 10-nvidia-drm-outputclass-custom.conf /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass-custom.conf"

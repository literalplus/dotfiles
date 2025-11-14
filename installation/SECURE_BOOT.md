# Secure Boot

pacman -Sy efitools efibootmgr sbctl

easiest is to just not update bootctl, this saves re-signing the keys ... ig

https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot

We're using preloader

need to use aur package preloader-signed

sudo -u pnowak yay -Syu preloader-signed
cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi /boot/EFI/systemd
cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi
efibootmgr --unicode --disk /dev/nvme0n1 --part 1 --create --label "PreLoader" --loader /EFI/systemd/PreLoader.efi

we could also use shim which supports signing and then we don't need to re-approve the binaries when booting.
but that is anyways possible with MokManager, thus there is no security benefit to using signing.

bootctl update -> this just copies the binary to the EFI partition & sets the efibootmgr entry.
thus we don't need to do that. We need to change the pacman hook for bootctl to just copy it to the
right location, the efibootmgr for preloader stays the same anyways.

cleaning up old hashes can be done by installing the KeyTool.efi and booting it to manage the hashes:

pacman -S efitools
cp /usr/share/efitools/efi/KeyTool.efi /boot/EFI/systemd/KeyTool.efi

This setup only signs the preloader and enrols the hash of the boot loader.
The kernel and initrams are in no way verified.

## secure boot fixing 2025-11-13

boot via preloader -> debian live

hold space to enter menu

```
cryptsetup open /dev/nvme...p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount /dev/nvme...p1 /mnt/boot
apt install arch-install-scripts
arch-chroot /mnt

sudo -u pnowak -i
git clone ...shim-signed AUR
cd shim-signed
makepkg -si
cp /boot/EFI/BOOT/BOOTx64.EFI grubx64.efi # shim requires this, actually systemd-boot
cp /usr/share/shim-signed/shimx64.efi .
cp /usr/share/shim-signed/mmx64.efi .
efibootmgr --unicode --disk /dev/nvme.. --part 1 --create --label "Shim" --loader /EFI/BOOT/shimx64.efi

# Delete the sbctl keys at /var/lib/sbctl ...
pacman -Sy linux linux-firmware
```

rescue systems:

`archiso-systemd-boot` -> this doesn't have Secure Boot support so must be loaded via shim/preloader ... anyways it's too big ~1.2Gi

https://wiki.archlinux.org/title/Systemd-boot#Recovery_Arch_image_on_the_ESP_with_Secure_Boot

https://codeberg.org/swsnr/rescue-image -> `yay -Sy mkosi systemd-ukify cpio`

-> https://github.com/literalplus/archlinux-rescue-image-fork
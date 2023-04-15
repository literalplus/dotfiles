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



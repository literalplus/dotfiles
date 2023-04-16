# Arch setup

## On the live system

Use `archsetup.sh` for Arch Linux setup from archboot (not archiso; it doesn't have Secure Boot support). https://pkgbuild.com/~tpowa/archboot/web/archboot.html

The image can be written to a USB stick using `cp img.iso /dev/sda`.

Note that for the default vanilla archiso, the default kernel line allocates no extra space, which you need to clone the git repo. To change this,
append `cow_spacesize=1G` to the kernel line when booting.

## Secure Boot

The boot loader setup uses systemd-boot and, if selected, PreLoader for Secure Boot. Please note that this is note the most secure setup, as anything signed by the Microsoft 3rd Party Key can be booted. A more secure setup would be to install a custom key (not possible without putting Secure Boot into Setup Mode) and manually sign kernel and initramfs. At least the current setup requires user interaction to enrol new bootloader hashes (and they can't just be signed with root access) — However, with root access lost, many other attacks are anyways already possible. In addition, PreLoader doesn't validate neither kernel nor initramfs, so malicious code can easily be inserted there while the machine is running.

## Continue setup on the new system

After rebooting, WiFi can be temporarily set up like this:

```bash
nmcli radio wifi on
nmcli dev wifi list
nmcli dev wifi connect <<SSID>> password "<<password>>"
```

Complete further setup:

```bash
localectl set-x11-keymap de # not possible in chroot
./sysapply.sh
./apply.sh
# NVIDIA graphics card setup; check for changes:
# ref: https://wiki.archlinux.org/title/NVIDIA
# ref: https://wiki.archlinux.org/index.php/NVIDIA_Optimus#Use_NVIDIA_graphics_only (DisplayLink)
# Editing ~/.xinitrc doesn't seem to be necessary
./nvidia-setup.sh

sudo systemctl enable gdm
```

Reboot to test GDM boot.

## Setup in GNOME

### Keyboard Shortcuts

* Disable default screenshot shortcuts under "Screenshots"
* Disable Windows / Move window shortcut
* `Super+U -> /usr/local/bin/rofi-uuid`
* `Super+. -> /usr/local/bin/rofi-emoji`
* `Audio next -> dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next`
* `Audio previous -> dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous`
* `Audio play -> dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause`
* `Print -> screenwrap-open /tmp/ viewnior -a`
* `Shift+Print -> screenwrap-open /home/lit/Screenshots/ viewnior -a`
* `Ctrl+Print -> flameshot gui`
* `Super+X -> albert toggle`
* `Super+R -> gnome-terminal`
* `Super+V -> copyq toggle`
* `Super+Y -> rofi-window`
* `Super+F -> context-select-k9s`

Disable conflicting Ctrl-Shift-U shortcut in `ibus-setup` utility (Install `ibus` for this).

### Manual system settings

 * Adjust PAM auto lockout (default 3 logins, lock for 10 minutes) https://wiki.archlinux.org/index.php/Security#Lock_out_user_after_three_failed_login_attempts
 * `/etc/pacman.conf` -> `ILoveCandy`, `ParallelDownloads=5`
 * `volta install node && volta setup`
 * npm global packages without sudo: https://stackoverflow.com/a/59227497 (`npm config set prefix '~/.local/'`)
 * Add yourself to the `wireshark` group

### Set up applications

 * Chrome
 * Albert
 * Nextcloud
 * Telegram
 * Desktop background
 * IDE, Maven, NPM

### Docker

Docker Secret Service: https://aur.archlinux.org/packages/docker-credential-secretservice + edit `~/.docker/config.json` https://aur.archlinux.org/packages/docker-credential-secretservice

Docker login

See: https://wiki.archlinux.org/title/Nftables#Working_with_Docker



### Sound card not recognised

Newer laptops might need the `sof-firmware` package for the internal sound card to be recognised properly.

### GNOME Theme
GTK Theme: Ant Nebula - [GNOME Look](https://www.gnome-look.org/p/1099856/), [Github](https://github.com/EliverLara/Ant-Nebula)

-> `~/.themes`

Icon Theme: Boston - [GNOME Look](https://www.gnome-look.org/p/1012402/), [Github](https://github.com/heychrisd/Boston-Icons)

-> `~/.icons`

## Re-install Bootloader when necessary

Not part of the installation, just noted here.

### GRUB

````bash
sudo grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=FreshGRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo mkinitcpio -P
````

### systemd-boot

```bash
sudo systemctl restart systemd-boot-update
sudo mkinitcpio -P
# Secure Boot / PreLoader
sudo cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi
```

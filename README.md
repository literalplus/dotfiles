# Dotfiles
Symlink them to where you need them.

Create a file `is-personal` to allow personal configuration.

Use `apply.sh` to apply user-level configuration.

Use `sysapply.sh` to apply system-level configuration.

## Arch setup
Use `archsetup.sh` for Arch Linux setup from archboot (not archiso; it doesn't have Secure Boot support). https://pkgbuild.com/~tpowa/archboot/web/archboot.html

Note that for the default vanilla archiso, the default kernel line allocates no extra space, which you need to clone the git repo. To change this,
append `cow_spacesize=1G` to the kernel line when booting.

After rebooting, WiFi can be temporarily set up like this:

```bash
nmcli radio wifi on
nmcli dev wifi list
nmcli dev wifi connect <<SSID>> password "<<password>>"
```

### Manual steps

 * Install NVIDIA driver https://wiki.archlinux.org/title/NVIDIA
 * Switch to NVIDIA-only mode for external screens / DisplayLink support https://wiki.archlinux.org/index.php/NVIDIA_Optimus#Use_NVIDIA_graphics_only
 * Set up shortcuts in GNOME
  * Disable default screenshot shortcuts under "Screenshots"
  * Disable Windows / Move window shortcut
  * `Super+U -> /usr/local/bin/rofi-uuid`
  * `Super+. -> /usr/local/bin/rofi-emoji`
  * `Audio next -> dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next`
  * `Audio previous -> dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous`
  * `Audio play -> dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause`
  * `Print -> screenwrap-open /tmp/ viewnior -a`
  * `Shift+Print -> screenwrap-open /home/lit/Screenshots/ -a`
  * `Ctrl+Print -> flameshot gui`
  * `Super+X -> albert toggle`
  * `Super+R -> gnome-terminal`
  * `Super+V -> copyq toggle`
  * `Super+Y -> rofi-window`
  * `Super+F -> context-select-k9s`
 * Disable conflicting Ctrl-Shift-U shortcut in `ibus-setup` utility
 * Desktop background
 * Nextcloud
 * Telegram
 * Adjust PAM auto lockout (default 3 logins, lock for 10 minutes) https://wiki.archlinux.org/index.php/Security#Lock_out_user_after_three_failed_login_attempts
 * `/etc/pacman.conf` -> `ILoveCandy`, `ParallelDownloads=5`
 * npm global packages without sudo: https://stackoverflow.com/a/59227497
 * Add yourself to the `wireshark` group

### GNOME Theme
GTK Theme: Ant Nebula - [GNOME Look](https://www.gnome-look.org/p/1099856/), [Github](https://github.com/EliverLara/Ant-Nebula)
Icon Theme: Boston - [GNOME Look](https://www.gnome-look.org/p/1012402/), [Github](https://github.com/heychrisd/Boston-Icons)

## GRUB commands

````bash
sudo grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=FreshGRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
````
## systemd-boot commands

```bash
sudo systemctl restart systemd-boot-update
# NOTE: Secure Boot / PreLoader move!
```

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
sudo systemctl enable gdm
```

## NVIDIA Drivers

NVIDIA graphics card setup; check for changes:

https://wiki.archlinux.org/title/NVIDIA

https://wiki.archlinux.org/index.php/NVIDIA_Optimus#Use_NVIDIA_graphics_only

Editing ~/.xinitrc doesn't seem to be necessary.

We are using only the NVIDIA GPU and disabling the Intel GPU, since that seemed to be the only working option with
DisplayLink, which may or may not have changed in the meantime.

Viable (but not yet tested) other options options:
 * https://wiki.archlinux.org/title/NVIDIA_Optimus#Using_PRIME_render_offload - official
 * https://wiki.archlinux.org/title/NVIDIA_Optimus#Using_switcheroo-control - Bumblebee-like, specific to GNOME, controlled
    by desktop entries. Unclear if it has the same performance issues.
 * https://wiki.archlinux.org/title/NVIDIA_Optimus#Using_NVidia-eXec - experimental solution also working on Wayland,
    apparently much better performance.

**Note:** All of these options are mutually exclusive, if you test one approach and decide for another, you must ensure to revert any configuration changes done by following one approach before attempting another method, otherwise file conflicts and undefined behaviours may arise.

Note that the script asks you to add the KMS modesetting parameter. Whether this is necessary or useful depends on the
selected option. In the default setup, it should be used.

```
./nvidia-setup.sh
```

NVIDIA needs some additional love to work with Wayland on GDM. This may or may not conflict with NVIDIA Optimus.
The following advice is also untested as of yet.

https://bbs.archlinux.org/viewtopic.php?pid=2035351#p2035351

https://wiki.archlinux.org/title/GDM#Wayland_and_the_proprietary_NVIDIA_driver

https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Preserve_video_memory_after_suspend ..?


### Reboot

Reboot to test GDM boot.


## Setup in GNOME

### Keyboard Shortcuts

* Disable default screenshot shortcuts under "Screenshots"
* Disable Windows / Move window shortcut
* Change `Switch windows directly` to `Alt-Tab`, this also disables the default "Switch applications" binding for it.
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
* `Super+Shift+F -> context-select-k9s`
* `Super+F -> keyboard-shortcut-k9s`

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

#### Network Namespaces for nftables

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d/
sudo cp docker-netns.conf /etc/systemd/system/docker.service.d/netns.conf
```

This uses a veth pair on the `192.168.250.0/24` network with the sides
assigned to `192.168.250.10` (host) and `192.168.250.11` (docker).

The Docker side is default-routed via the host, and the host side receives
a route for the Docker networks. It is crucial that the routed network matches
the network that Docker actually uses. Also note that it is not possible to fully
overlap the bridge network with Docker's IPAM network, as it will (rightfully)
complain that no IP addresses are available. With our setup, it would detect that
this specific `/24` is unavailable and just assign the remaining networks.
However, it is not possible to add a route ion the host that overlaps with
the bridge IP space, so we have to use disjoint networks.

As a result, `192.168.128.0/18` is left for Docker to assign. A different setup
could be used by relying on other private networks (e.g. using IPs from `192.168.0.0/17`),
but most of these are sadly already used & specifically the upper half of `192.168.0.0`
is recommended for the Docker network by my company, thus this one should be safe to use.

Docker wants to resolve DNS queries at `127.0.0.53` (systemd-resolved stub resolver),
which doesn't work any more in the separate network namespace. To solve this:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo cp 12-docker-access.conf /etc/systemd/resolved.conf.d/12-docker-access.conf
```

Finally, let's also inform Docker about our intentions:

`/etc/docker/daemon.json`

```json
{
    "registry-mirrors": ["https://docker-mirror.internal.cloudflight.io", "https://mirror.gcr.io"],
    "default-address-pools": [
        {
            "base": "192.168.128.0/18",
            "size": 24
        }
    ],
    "dns": ["192.168.250.10"]
}
```

A nice side-effect of this setup is that Docker containers can also use any
VPN connections the host may have running. This is especially useful in
corporate networks.

To make this work, IPv4 Forwarding needs to be enabled. The systemd hook does this automatically when starting Docker.

#### Issue: Fails to find any entrypoint

```
➜  ~ docker run --rm alpine:3        
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "/bin/sh": stat /bin/sh: no such file or directory: unknown.
```

This means that containerd and docker are not running in the same filesystem namespace (`PrivateMounts=yes` on `docker.service`). 

#### Run a command in the docker netns

Some applications (*cough* Testcontainers) expose ports dynamically.
Use `sudo enter-docker-ns <your command>` to run a command in the Docker namespace
where dynamic ports work.

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

Example overrides in `/etc/default/grub`:

```
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="i915.enable_psr=1 i915.fastboot=1 i915.enable_guc=2 acpi_osi=Linux rd.luks.name=596d8feb-77bb-4b1d-afea-b53d5bef668f=cryptroot nvidia-drm.modeset=1"

GRUB_DISABLE_OS_PROBER=false
```

### systemd-boot

```bash
sudo systemctl restart systemd-boot-update
sudo mkinitcpio -P
# Secure Boot / PreLoader
sudo cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi
```

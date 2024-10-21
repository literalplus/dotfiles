# Dotfiles
Symlink them to where you need them.

Create a file `is-personal` to allow personal configuration.

Use `apply.sh` to apply user-level configuration.

Use `sysapply.sh` to apply system-level configuration.

Installation: [INSTALL.md](installation/INSTALL.md)

## UEFI Upgrade

not attempted yet, but

https://wiki.archlinux.org/title/Fwupd#Setup_for_UEFI_upgrade

https://github.com/fwupd/fwupd/issues/3762#issuecomment-1614257168

Issue is that we need shim but this setup uses PreLoader. unclear if system will break when installing shim

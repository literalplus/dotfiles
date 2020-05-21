# Dotfiles
Symlink them to where you need them.

Create a file `is-personal` to allow personal configuration.

Use `apply.sh` to apply user-level configuration.

Use `sysapply.sh` to apply system-level configuration.

## Arch setup
Use `archsetup.sh` for Arch Linux setup from archiso.

Note that the default kernel line allocates no extra space. To change this,
append `cow_spacesize=1G` to the kernel line when booting.


https://bbs.archlinux.org/viewtopic.php?id=294185
 -> pacman -Qikk at-spi2-core
 -> export NO_AT_BRIDGE=1

https://www.reddit.com/r/linux4noobs/comments/16oscj0/gnome_oh_no_something_hass_gone_wrong_error_when/
 -> https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/3329?commit_id=b7a1159a1ecd08b5e6aa1279fea84accf846b411 this seems to fix it but no activity (the crash when reloading)

Hey, about the sleep problem. Its been a while so mabye you fixed it, but it became annoying for me so I researched it a bit. Apparently is been a known gnome bug for about 10 months or so, but it's considered low priority and probably won't be fixed in the near future... However, there is a workaround that works on some hardware. Setting MUTTER_DEBUG_ENABLE_ATOMIC_KMS=0 in /etc/environment and restarting fixed it for me.


https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7050

https://bbs.archlinux.org/viewtopic.php?id=296698
 -> Should be fixed in GDM 47, or possibly GDM 46.3 if that becomes a thing.
 -> Gdm: on_display_added: assertion 'GDM_IS_REMOTE_DISPLAY (display)' failed
 -> no effect


 https://unix.stackexchange.com/questions/779873/arch-linux-gdm-is-defaulting-to-x11-instead-of-wayland-whats-up-with-my-confi
 
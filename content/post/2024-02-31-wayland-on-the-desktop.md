+++
date = "2024-02-28"
description = "Wayland on the Desktop"
title = "Desktop 2024"
slug = "2024-02-28-wayland-on-the-desktop"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["linux"]
+++

wtf

<!--more-->

## Hyprland

Remaining movment in my [dotfiles](https://github.com/clux/dotfiles) this year has largely been due the move to [hyprland](https://hyprland.org/). This is my first tiling window manager (replacing my tried-and-true/boring `cinnamon`) and it came with a bunch of replacement tooling as you are expected to install a bunch of tools along with the `hyprland` package.

The [recommended utilities list](https://wiki.hyprland.org/Useful-Utilities/) got me operational quickly, and then it's basically figuring out what you want. My favourite stand-alone pieces are:

- [dunst](https://github.com/dunst-project/dunst) :: notification manager (`dunstctl` is great)
- [wofi](https://sr.ht/~scoopta/wofi/) / [fuzzel](https://codeberg.org/dnkl/fuzzel) :: fuzzy launchers - both good
- [greetd](https://sr.ht/~kennylevinsen/greetd/) :: autologin on desktop (initramfs needs my luks pw anyway)
- [swaylock](https://github.com/swaywm/swaylock) / [wleave](https://github.com/AMNatty/wleave) :: lock screen and logout initiators
- [grim](https://git.sr.ht/~emersion/grim) / [slurp](https://github.com/emersion/slurp) :: screen shotting
- [waybar](https://github.com/Alexays/Waybar) :: super customizable menu bar that needs to hook into the above

Some churn from the big [hyprland.conf](https://github.com/clux/dotfiles/blob/main/config/hypr/hyprland.conf) and they [waybar configs](https://github.com/clux/dotfiles/blob/main/config/waybar/config.jsonc), but all in all, the wayland journey has been very educational and positive. The system feels less like an opaque black box (like Xorg did), and more like a collection of composable tools with well-defined interfaces.

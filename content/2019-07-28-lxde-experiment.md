+++
date = "2019-07-28"
description = "How useful is a power optimized WM these days?"
title = "Trying out LXDE"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["linux"]
+++

Despite having been a lazy Cinnamon customer since the Linux Mint days, recently some [interesting](https://old.reddit.com/r/linux_gaming/comments/cii545/linux_input_lag_analysis_v26des_windows_10_1809/) benchmarks started [surfacing](https://www.reddit.com/r/linux_gaming/comments/c0ly6b/linux_input_lag_analysis7des_tested_windows/) about input lag in various Window Mangagers, and this made me want to experiment a little.

This is a log of stuff I needed to tweak to get [LXDE](https://wiki.archlinux.org/index.php/LXDE) working well.

<!--more-->

# LXDE
> LXDE is a free desktop environment with comparatively low resource requirements. This makes it especially suitable for use on older or resource-constrained personal computers such as netbooks or system on a chip computers.

Alrighty. A `C` based WM using `GTK+ 2`. Not used this since Gnome 2, back in the 2012 days.

## Installation
Already had Arch Linux running [LightDM](https://wiki.archlinux.org/index.php/LightDM) as my Display Manager, so only needed the base install:

```sh
$ sudo pacman -S lxde
Packages (24) libfm-1.3.1-1  libfm-extra-1.3.1-1  libfm-gtk2-1.3.1-1  libwnck-2.31.0-2
              lxmenu-data-0.1.5-2  menu-cache-1.1.0-1  xmms2-0.8DrO_o.949.gca15e830-18
              gpicview-0.2.5-4 lxappearance-0.6.3-2  lxappearance-obconf-0.2.3-2
              lxde-common-0.99.2-2  lxde-icon-theme-0.5.1-4  lxdm-0.5.3-6  lxhotkey-0.1.0-2
              lxinput-0.3.5-2  lxlauncher-0.2.5-3 lxmusic-0.4.7-2  lxpanel-0.10.0-1
              lxrandr-0.3.2-1 xsession-1:0.5.4-1  lxtask-0.1.9-1  lxterminal-0.3.2-1
              openbox-3.6.1-4  pcmanfm-1.3.1-1
```

Then, logged out of `cinnamon`, and switched WM from the login screen to `LXDE`. Easy.

## Input Lag
Tested this out immediately to see if it felt better. Funnily enough, I can only tell in certain games that require a bunch of precise inputs. Most of my other currently installed games felt the same. But they aren't really twitchy enough to tell.

That said, `Necrodancer` definitely felt better. No longer any recogonizable input lag when playing `Bolt` or `Coda`, and had issues with those before on `cinnamon`.

## Quirks
### Keyboard bindings
To be able to use this at all, I need some keyboard shortcuts to move windows between monitors. I tend to use `Super+Left` and `Super+Right`.

It was quite akward to set this up with `lxhotkey`. The magical incantation (which took almost an hour to figure out) was:

- `"MoveResizeTo": "monitor:prev" : <Super>Left`
- `"MoveResizeTo": "monitor:next" : <Super>Right`

Interestingly, `lxhotkey` is a [700 line .c file](https://github.com/lxde/lxhotkey/blob/master/src/lxhotkey.c) last touched 3 years ago.

No way to bind `Super` to open the main menu AFAIKT, and man, that was hard to unlearn. Not that it matters, because there's no fuzzy start and type on the main menu anyway. Amazing how tied you get to that. Not sure I can deal with not having that now. Maybe there's some kind of `fzf` panel type thing I can install?

## Missing out of the box
### Screen locker
Screensaver button kept spinning, timing out. Turns out `xscreensaver` was not installed. Installing it fixed it, but it also pulled in like 15 perl packages, and looked absolutely awful.

Ended up installing `slock` straight from pacman instead. No dependencies there, and [it's one c file](https://git.suckless.org/slock/file/slock.c.html). No user input. Just a tree color screen. Black when locked, blue while typing, red on wrong password.

Didn't have to actually write `slock` anywhere. It just worked after installing it (`lxlock` apparently figures this out). I had taken out the broken `xscreensaver` ref in `~/.config/lxsession/LXDE/autostart` anyway though.

### Transparency
This is kind of necessary for me for any terminals as I frequently overlay them on code with ~70% opacity. Installing `xcompmgr` straight from pacman and adding `xcompmgr &` to `~/.config/lxsession/LXDE/autostart` fixed it.

## Look and feel
## Main panel
Needed about 15 minutes of configuration, and it ended up being stored in a 129 line file in `~/.config/lxpanel/LXDE/panels/panel` But ended up looking very nice. Transparency on the bar itself was a nice touch.

![](/imgs/wms/lxde2-transparency.jpg)

Though you can see that it gets confused if you have set a different background on each monitor, which is something you can do for some reason.

![](/imgs/wms/lxde2-dual-bg.jpg)

## File manager
Fine, could make it look like `nemo` in 5 minutes. You can see it in the background above. Had it's config in a tiny: `~/.config/pcmanfm/LXDE/pcmanfm.conf`.

## General Theme
Default theme is quite ugly due to the overly glossy black panel, so you probably have to that transparent anyway. Everything kind of only fits the dark theme IMO. Went for the only decent one: `Adwaita-dark`, but put on `Mikachu` window borders. Nothing amazing, but completely fine.

Tiny file in `~/.config/lxsession/LXDE/desktop.conf` controls this.

Articles [exist](https://www.addictivetips.com/ubuntu-linux-tips/lxde-themes/) online on how to install themes for it, but that's probably the gtk3 version. The few I tried didn't work.

# Verdict
The most awkward thing is the lack of a launcher bar so far. Performance is great. Keybindings are mostly workeable. If some better tiling-like commands can be set up maybe you can make do with `alacritty`.

Seems completely useable. Most configs [stashed in this PR](https://github.com/clux/dotfiles/pull/31/files).

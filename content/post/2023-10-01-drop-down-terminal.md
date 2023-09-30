+++
date = "2023-10-01"
title = "Drop Down Terminal"
slug = "2023-10-01-drop-down-terminal"
description = "Recreating guake on top of alacritty and zellij in wayland and macos"

[extra]
toc = true
math = false

[taxonomies]
categories = ["software"]
tags = ["linux", "mac"]
+++

As a former Quake player, I have been a long-term user of [guake](https://github.com/Guake/guake) for a quick access terminal on Linux.

However, as `guake` is __gnome__ specific, continued use became problematic once a mac got thrust upon me for work. So herein is a workaround for making your own drop-down terminal for Linux and Mac by utilizing [alacritty](https://github.com/alacritty/alacritty) + [zellij](https://zellij.dev/).

<!--more-->

## Looks

[![alacritty in foreground with zellij tabs and helix open with transparency](/imgs/term-drop.png)](/imgs/term-drop.png)

This is using a transparent theme in `helix`, with 80% opacity in alacritty, and disabled blur in `hyprland` to selectively see through below (like for say live updates to the markdown rendering). On mac, the setup and looks are very similar to this.

> For times when transparency is too annoying you can [bind a key to change the `helix` theme](https://github.com/clux/dotfiles/blob/dfcf3d8eb3ae48b8f1ff0df0dffb7d2b7ec65680/config/helix/config.toml#L12-L13) to something fully opaque (most themes are opaque).

## Basic Setup

The idea is to have a __persistent terminal__ that is __hidden away__ in a "special place" and bind a key to toggle the visibility of this terminal. Then we rely on `zellij` to provide tabs.

> The choice of terminal emulator and multiplexer is not super important. You could probably use `kitty` + `tmux`, or straight `wezterm` (which has tabs mgmt built-in) if you prefer, and achieve the same results.

## Alacritty Setup
My preferred setup is to always launch `zellij` at `alacritty` start by configuring the default shell in the `alacritty.yml` config:

```yaml
shell:
  program: zsh
  # start zellij with a small sleep to ensure it gets right dimensions
  args:
   - -ic
   - sleep 0.2 && zellij -l compact
```

and, since this is a drop-down terminal we are selling, you probably also want transparency (because otherwise why do you need the window to go in front? just switch applications or workspaces):

```yaml
window:
  opacity: 0.8
```

on linux we can also make it as clean as possible and remove most window decorations:

```yaml
window:
  decorations: none
  startup_mode: Maximized
```

whereas on mac the nicest decoration setup is `buttonless`:

```yaml
window:
  decorations: buttonless
  startup_mode: Maximized
```

(and you can also experiment with binding a key to `ToggleSimpleFullscreen` there).

## Zellij Setup
Honestly, this is pretty nice out of the box. Mostly styling is nice here to make it cleaner:

```kdl
pane_frames false
ui {
    pane_frames {
        hide_session_name true
    }
}
```
grab a [theme](https://zellij.dev/documentation/themes).

> The `-l compact` startup option set in the alacritty config assumes familiarity in `zellij`, you're likely to find it easier to onboard if you don't use compact mode until you are familiar.


## Variants
### Hyprland
On Linux with [hyprland](https://hyprland.org/) (my current wayland compositor), plugging this in is very easy to do, and the solution is the most ergonomic out of the three.

In your `hyprland.conf`, add:

```hyprland
exec-once = [workspace special] alacritty
bind = , F1, togglespecialworkspace
```

so it auto-starts and you can toggle the workspace as you wish.

Give it an animation so it pops in vertically, and avoid undercutting your opacity:

```hyprland
animations {
    animation = specialWorkspace, 1, 1, default, slidevert
}
decoration {
    # don't dim modal terminal
    dim_special = 0
    blur {
      enabled = false # make it easy to see-through from special workspace
    }
}
```

And the final hyprland quirk; special workspaces have a window scaling factor (default `0.8`) that controls how much large the window is allowed to be. If you are putting a terminal editor in there or something you probably want to max that out:

```hyprland
dwindle {
    special_scale_factor = 1 # maximize special workspace
}
```

### Hammerspoon

On Mac, the easiest setup is using [hammerspoon](https://github.com/Hammerspoon/hammerspoon). Bind a toggle or start `alacritty` in your hammerspoon's `init.lua`:

```lua
local function toggleApp(name)
  local app = hs.application.find(name)
  if not app or app:isHidden() then
    hs.application.launchOrFocus(name)
  elseif hs.application.frontmostApplication() ~= app then
    app:activate()
  else
    app:hide()
  end
end

-- Global terminal toggle
hs.hotkey.bind({}, "F1", function() toggleApp("alacritty") end)
```

### Xorg

All setups I found for this were __comically bad__, but including one for completeness. **Don't use this**. Stay on `guake` if you are on `X`. This majorly struggles with multi-monitor.

> Aside: you should consider moving onto wayland if you haven't. At the very least all my blockers got resolved this year.

You need a script that auto-runs in your shell, and a runnable function:

```sh
# autorun via .zshrc
if [ -n "${ZELLIJ_SESSION_NAME}" ] && [ ! -f /tmp/wraise ]; then
# If running in zellij on linux, save the window for refocus keybinds
  xdotool getactivewindow > /tmp/wraise
fi

# function somewhere else (e.g. ~/.functions)
# setup a bind run: /bin/zsh -c 'source .functions && terminal_toggle'
terminal_toggle() {
  local -r terminal_id="$(cat /tmp/wraise)"
  # Check if it is active (stored in hex on a root prop)
  local -r active_id="$((16#$(xprop -root _NET_ACTIVE_WINDOW | choose 4 | cut -d'x' -f2)))"
  if [ $active_id -eq $terminal_id ]; then
    xdotool windowminimize "${terminal_id}"
  else
    wmctrl -ia "${terminal_id}"
  fi
}
```

This expects `alacritty` is on autorun and you can configure binds somewhere. I put an `F2` bind in `cinnamon` (yeah, long time between changing WMs for me) to run this.

> Again; **I don't use this**. I wrote it as a 1mo stop-gap and I hated it.

Having to support Mac + X in my [dotfiles](https://github.com/clux/dotfiles) became a perfect storm of frustration, and wouldn't you know it, wayland made everything better.

..as with many things, the answer is to [migrate away from X](https://hachyderm.io/@compositor@wayland.social/110768798344764115).

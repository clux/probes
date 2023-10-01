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

Behold; a semi-transparent, tabbed terminal hovering above two browser windows (showing the editing process of this very post):

[![alacritty in foreground with zellij tabs and helix open with transparency](/imgs/term-drop.png)](/imgs/term-drop.png)

This is using a transparent theme in [helix](https://helix-editor.com/), with 80% opacity in alacritty, and disabled blur in `hyprland` to selectively see through below (like for say live updates to the markdown rendering). On mac, the setup and looks are very similar to this.

> For times when transparency is too annoying you can [bind a key to change the `helix` theme](https://github.com/clux/dotfiles/blob/dfcf3d8eb3ae48b8f1ff0df0dffb7d2b7ec65680/config/helix/config.toml#L12-L13) to something fully opaque (most themes are opaque). A quick `F1` press ultimately slides the terminal away from view anyway.

## Core Concept

The idea is to have a __persistent terminal__ that is __hidden away__ in a "special place" and bind a key to toggle the visibility of this terminal. Then we rely on `zellij` to provide tabs.

> The choice of terminal emulator and multiplexer is not super important. You could probably use `kitty` + `tmux`, or straight `wezterm` (which has tabs mgmt built-in) if you prefer, and achieve the same results.

On __wayland__ that place is a __special workspace__, whereas on __mac__ we use `sticky` windows.

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

whereas on mac a similar decoration setup is `buttonless`:

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

### Tab Names
If you don't want to faff around with naming every single zellij tab, you can also make `zsh` do it automatically for you using [`chpwd_functions`](https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions) using something like this in your `.zshrc` etc:

```sh
zz() {
  if [ -n "${ZELLIJ_SESSION_NAME}" ]; then
    zellij action rename-tab "${PWD##*/}"
  fi
}

# ensure directory traversal updates tab names (if terminal mux exists)
chpwd_functions+=zz
zz # initialize name for new tabs/panes
```

This is nice because it catches all sources of traversal, be it through `cd` or through jumpers like [zoxide](https://github.com/ajeetdsouza/zoxide).

## Drop Down Variants
The most ergonomic one here is the hypland variant, but the mac setup is also decent.

### Hyprland
On Linux with [hyprland](https://hyprland.org/) (my current wayland compositor), plugging this in is very easy to do because you have access to [special workspaces](https://wiki.hyprland.org/Configuring/Dispatchers/#special-workspace), so the terminal is never technically __hidden__, it's just active in a different workspace.

> This might not seem like a big deal, but if you've tried sharing a terminal that hides itself (such as guake's or through the mac solution below) on a screen sharing video call, you will find various failure modes (from app crashes to stream closes) if you hide the window you are sharing.

In your `hyprland.conf`, add:

```hyprland
exec-once = [workspace special] alacritty
bind = , F1, togglespecialworkspace
```

so it auto-starts in special, and you can toggle the workspace as you wish.

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

The end result is a terminal that pops in from the bottom in an inverted quake terminal feel - and honestly this makes more sense than top-to-bottom since you have to give some space to the (usually top) `waybar`.

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

It is a little flimsy on a multi-monitor setup, with sometimes having to manually move it across to a workspace on a different monitor on boot (window/workspace/monitor hierarchy seems less clean on mac in general), but it helps to not auto-start the app and let the bind start it on the monitor you  have your cursor by only pressing the bind there.

The alacritty opacity setting is respected out of the box.

If you are using it with [yabai](https://github.com/koekeishiya/yabai) (for auto-tiling of windows, window moving shortcuts), then you also want to add a rule for `yabai` to mark it as sticky to avoid it getting bunched up as a normal window tile:

```sh
yabai -m rule --add app="^(Alacritty)$" sticky=on
```

Because it is using sticky windows, screen sharing of this window will not be viable by itself (as the source disappears when it's hidden), so you'll have to share the entire workspace instead. This is usually not a big deal if you are already using workspaces.

### Xorg

All setups I found for this were __comically bad__, but including one for completeness. **Don't use this**. Stay on `guake` if you are on `X`. The hack below majorly struggles with multi-monitor.

> Aside: you [should consider moving onto wayland](https://orowith2os.gitlab.io/posts/wayland-breaks-your-bad-software/) if you haven't.

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

> Again; **I don't use this**. I wrote it as a short stop-gap and I hated it.

Having to support Mac + X in my [dotfiles](https://github.com/clux/dotfiles) became a perfect storm of frustration, and wouldn't you know it, wayland made everything better.

..as with many things, the answer is to [migrate away from X](https://hachyderm.io/@compositor@wayland.social/110768798344764115).

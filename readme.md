# bspwm window titles

This script gives you the possibility to show all window titles on your current bspwm desktop on your bar.

Works with multi head and has been tested with polybar.
It needs to be launched as a daemon inside your `bspwmrc`.

## Reason

I use bspwm's monocle mode a lot and I kept forgetting what windows are on which desktop, cycling between them is a bit annyoing.

This scripts solves this by always showing all of the window titles in my bar and allows me to cycle between them with mouse clicks as well.

## How it looks

![preview](./img/window_titles.png)

Shows a vertical list of window titles. `[ window name ]` denotes currently active window.

It shows icon before each window title as well. Those are are `Material Icons` and `window_class_icon_map.txt` keeps a map of  `Window class [Icon]`. There is a fallback icon for when there is no icon for current program.

## How it works

- Subscribes to bpswm events
- Each event (node_focus, node_remove, desktop_focus) re-generates window titles for each currently visible desktop on all monitors
- Puts window titles in text files for use in a bar
- Left/Right click on window titles will focus previous/next window (polybar)

## Prerequisites

Programs:
- `bspwm`
- `polybar`
- `wmctrl`

Fonts:
- `JetBrains Mono`
- `Material icons`

## Installation

Installation guide assumes you are using polybar and a multi-monitor setup - should work with single monitor too.

- Download or `git clone` this repo
- Copy `bspwm/window_titles.sh` and `bspwm/window_class_icon_map.txt` to `~/.config/bspwm`
- `chmod +x window_titles.sh`
- Create a symlink `~/bin` `ln -s ../.config/bspwm/window_titles.sh ~/bin/window_titles`
- Add below to your `~/.config/bspwm/bspwmrc`:

```shell
# restart window titles daemon
pgrep -u $UID -f /bin/window_titles | xargs kill
window_titles &

# restart polybar
"${HOME}/.config/polybar/launch_polybar.sh" &
```

- Copy `polybar/config` to `~/.config/polybar/config` - or copy the relevant modules (`[module/windowlist]`, `[module/windowlist-N]`) if you know what you are doing
- Replace `YOUR_USERNAME` with your username inside `polybar/config`
- Copy `polybar/launch_polybar.sh` to `~/.config/polybar/launch_polybar.sh` and make it executable `chmod +x` - or copy the relevant bits if you know what you are doing
- Restart bspwm

## Customization

### Don't generate window titles if there is only one window on desktop

Uncomment below in `bspwm/window_titles.sh`:

```shell
# don't print names if there is only one
# [[ "$number_of_windows" == "1" ]] && windows_print="" || windows_print="$curr_wins"
```

It won't generate window titles if there is only one window on that desktop.

### Add your own icons

Add a new line in `bspwm/window_class_icon_map.txt`

```
WINDOWCLASS ICON
```

#### Window class

To get window class name (you need `xprop`):

```
xprop | grep WM_CLASS
```

Click on program you would like to get the class of.

Sample output:

```
WM_CLASS(STRING) = "code", "Code"
```

Window class is `Code`.

#### Icon

To copy icon font to your clipboard you can use [gucharmap](https://github.com/polybar/polybar/wiki/Fonts) as explained in polybar's wiki.

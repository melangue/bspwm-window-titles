# bspwm_window_titles daemon

This script gives you the possibility to show all window titles on your current bspwm desktop on your bar.

Works with multi head and has been tested with polybar.
It needs to be launched as a daemon inside your `bspwmrc`.

## Reason

I use bspwm's monocle mode a lot and I kept forgetting what windows are on which desktop, cycling between them is a bit annyoing.

This scripts solves this by always showing all of the window titles in my bar and allows me to cycle between them with mouse clicks as well.

## How it looks

![preview](./img/window_titles.png)

Shows a vertical list of window titles. `[ window name ]` denotes currently active window.

It shows icon before each window title as well. Those are are `Material Icons` and `bspwm_window_titles_icon_map.txt` keeps a map of  `Window class [Icon]`.

There is a fallback icon for when there is no icon for current program.

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

Fonts can be replaced, but you will need to provide your own `WINDOWCLASS -> ICON` mappings to be able to display icons, more on that below.

## Installation

Installation guide assumes you are using polybar, have some sort of `launch_polybar.sh` script (which takes care of restarting polybar) and a multi-monitor setup - should work with single monitor setups too.

- Download or `git clone` this repo
- Copy `bspwm/bspwm_window_titles.sh.sh` and `bspwm/bspwm_window_titles_icon_map.txt` to `~/.config/bspwm`
- `chmod +x bspwm_window_titles.sh`
- Create a symlink `~/bin` `ln -s ../.config/bspwm/bspwm_window_titles.sh ~/bin/bspwm_window_titles`
- Add below to your `~/.config/bspwm/bspwmrc`:

```shell
# restart window titles daemon
while pgrep -u $UID -f bspwm_window_titles >/dev/null; do pkill -f bspwm_window_titles; done
bspwm_window_titles &
```

- Create (or edit) your `launch_polybar.sh` so it look similar to the below. I am using 3 separate bars, you could be using single one.
Note the for loop exporting dynamic values for monitors in order bspwm sees them.
This part is pretty important as it ensure that the right window titles will show on the right monitor.

```shell
CPID=$(pgrep -x polybar)

if [ -n "${CPID}" ] ; then
  kill -TERM ${CPID}
fi

# add window titles
# using bspc query here to get monitors in the same order bspwm sees them
for m in $( bspc query -M --names ); do
    index=$((index + 1))
    export P_BSPWM_WINDOW_CMD="tail ${HOME}/.cache/bspwm_windows_${index}.txt"

    MONITOR=$m polybar --reload right &
    MONITOR=$m polybar --reload left &
    MONITOR=$m polybar --reload center &
done
```

- Add the below module (and sample bar) to your polybar config and adjust to match your setup.
If you want to change the icon font, take a look at 'Customization'  section of this readme.

```shell
## base setup
[bar/base]
monitor                       = ${env:MONITOR}
locale                        = en_US.UTF-8
dpi                           = 96
height                        = 18
offset-y                      = 8
font-0                        = JetBrains Mono:style=Regular:size=10;2
font-1                        = Material Icons:style=Regular:size=9;2
background                    = #000
foreground                    = #FFF


## center bar
[bar/center]
inherit                       = bar/base
width                         = 60%
offset-x                      = 350

fixed-center                  = true
modules-center                = windowlist

## module
[module/windowlist]
type = custom/script
interval = 0.5
exec = ${env:P_BSPWM_WINDOW_CMD}

; cycle between windows
click-left = bspc node -f next.local
click-right = bspc node -f prev.local

format = <label>
format-background = #000
format-foreground = #FFF
format-padding = 4
```

- Restart bspwm

## Customization

### Don't generate window titles for desktop if there is only one window

Change `bspwm_window_titles &` to `bspwm_window_titles nomonocle &` in `~/.config/bspwm/bspwmrc`

### Add your own icons

Add a new line in `bspwm/bspwm_window_titles_icon_map.txt`

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

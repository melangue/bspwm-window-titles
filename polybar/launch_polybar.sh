#!/usr/bin/env bash

CPID=$(pgrep -x polybar)

if [ ! -z "${CPID}" ] ; then
  kill -TERM ${CPID}
fi

for m in $( polybar --list-monitors | cut -d ':' -f1 ); do
    MONITOR=$m polybar --reload right &
    MONITOR=$m polybar --reload left &
done

# add window titles
# using bspc query here to get monitors in the same order bspwm sees them
for m in $( bspc query -M --names | cut -d ':' -f1 ); do
    index=$((index + 1))
    MONITOR=$m polybar --reload "center-${index}" &
done

#!/bin/sh

polybar-msg cmd quit

while pgrep -x polybar >/dev/null; do
    sleep 0.2
done

for monitor in $(polybar -m | cut -d: -f1); do
    MONITOR="$monitor" polybar example &
done

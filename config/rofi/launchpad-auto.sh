#!/bin/bash
# Launchpad-like application launcher for Rofi
# Shows only apps with icons

rofi -show drun \
    -theme "$HOME/.config/rofi/launchpad.rasi" \
    -drun-display-format "{name}" \
    -show-icons
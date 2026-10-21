#!/bin/bash
# Launchpad-like application launcher for Rofi

rofi -show drun \
    -theme "$HOME/.config/rofi/launchpad.rasi" \
    -drun-display-format "{name}" \
    -show-icons \
    -sidebar-mode
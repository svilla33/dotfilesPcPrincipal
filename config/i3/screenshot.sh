#!/bin/bash
dir="/home/suli/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/screenshot_$(date +%Y%m%d_%H%M%S).png"

if [ "$1" = "region" ]; then
    maim -s "$file"
else
    maim "$file"
fi

xclip -selection clipboard -t image/png -i "$file"

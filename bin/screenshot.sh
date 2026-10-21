#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/Screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

grim -g "$(slurp)" "$FILE" && wl-copy < "$FILE"

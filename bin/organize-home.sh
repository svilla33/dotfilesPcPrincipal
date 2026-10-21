#!/bin/bash
# organize-home.sh - Mueve archivos sueltos de ~/ a carpetas estandar

HOME_DIR="$HOME"

# Crear carpetas si no existen
mkdir -p "$HOME_DIR/Videos" "$HOME_DIR/Pictures" "$HOME_DIR/Music" "$HOME_DIR/scripts" "$HOME_DIR/Documents"

echo "=== Organizando archivos sueltos de home ==="

# Videos (.mp4, .webm, .mkv)
echo "Moviendo videos..."
for f in "$HOME_DIR"/*.mp4 "$HOME_DIR"/*.webm "$HOME_DIR"/*.mkv; do
    [ -e "$f" ] || continue
    mv -v "$f" "$HOME_DIR/Videos/"
done

# Imagenes (.png, .jpg, .jpeg)
echo "Moviendo imagenes..."
for f in "$HOME_DIR"/*.png "$HOME_DIR"/*.jpg "$HOME_DIR"/*.jpeg; do
    [ -e "$f" ] || continue
    mv -v "$f" "$HOME_DIR/Pictures/"
done

# Musica (.mp3)
echo "Moviendo musica..."
for f in "$HOME_DIR"/*.mp3; do
    [ -e "$f" ] || continue
    mv -v "$f" "$HOME_DIR/Music/"
done

# Scripts (.sh)
echo "Moviendo scripts..."
for f in "$HOME_DIR"/*.sh; do
    [ -e "$f" ] || continue
    mv -v "$f" "$HOME_DIR/scripts/"
done

# Documentos (.json, .circ, .ttc, .CKT, .SSF)
echo "Moviendo documentos..."
for f in "$HOME_DIR"/*.json "$HOME_DIR"/*.circ "$HOME_DIR"/*.ttc "$HOME_DIR"/*.CKT "$HOME_DIR"/*.SSF; do
    [ -e "$f" ] || continue
    mv -v "$f" "$HOME_DIR/Documents/"
done

echo "=== Organizacion de home completada ==="

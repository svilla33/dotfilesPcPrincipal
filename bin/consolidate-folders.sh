#!/bin/bash
# consolidate-folders.sh - Consolida carpetas duplicadas

HOME_DIR="$HOME"

echo "=== Consolidando carpetas duplicadas ==="

# 1. ~/music/ → ~/Music/
if [ -d "$HOME_DIR/music" ]; then
    echo "Fusionando ~/music/ en ~/Music/..."
    mkdir -p "$HOME_DIR/Music"
    cp -rv "$HOME_DIR/music/"* "$HOME_DIR/Music/" 2>/dev/null
    rm -rv "$HOME_DIR/music"
fi

# 2. ~/games/ (vacia) → eliminar
if [ -d "$HOME_DIR/games" ]; then
    if [ -z "$(ls -A "$HOME_DIR/games")" ]; then
        echo "Eliminando ~/games/ (vacia)..."
        rmdir "$HOME_DIR/games"
    else
        echo "AVISO: ~/games/ no esta vacia, saltando..."
    fi
fi

# 3. PS2: ~/ps2/ + ~/ps2smbdocker/ + ~/Documents/ps2Cosas/ → ~/Documents/ps2/
echo "Consolidando carpetas PS2 en ~/Documents/ps2/..."
mkdir -p "$HOME_DIR/Documents/ps2"

if [ -d "$HOME_DIR/ps2" ]; then
    cp -rv "$HOME_DIR/ps2/"* "$HOME_DIR/Documents/ps2/" 2>/dev/null
    rm -rv "$HOME_DIR/ps2"
fi

if [ -d "$HOME_DIR/ps2smbdocker" ]; then
    cp -rv "$HOME_DIR/ps2smbdocker/"* "$HOME_DIR/Documents/ps2/" 2>/dev/null
    rm -rv "$HOME_DIR/ps2smbdocker"
fi

if [ -d "$HOME_DIR/Documents/ps2Cosas" ]; then
    cp -rv "$HOME_DIR/Documents/ps2Cosas/"* "$HOME_DIR/Documents/ps2/" 2>/dev/null
    rm -rv "$HOME_DIR/Documents/ps2Cosas"
fi

# 4. ~/compartirvm/ → ~/Documents/compartirvm/
if [ -d "$HOME_DIR/compartirvm" ]; then
    echo "Moviendo ~/compartirvm/ a ~/Documents/..."
    mv -v "$HOME_DIR/compartirvm" "$HOME_DIR/Documents/"
fi

echo "=== Consolidacion completada ==="

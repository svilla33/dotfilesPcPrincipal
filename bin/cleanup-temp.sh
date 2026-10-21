#!/bin/bash
# cleanup-temp.sh - Elimina archivos temporales

HOME_DIR="$HOME"

echo "=== Eliminando archivos temporales ==="

# Archivos .tmp
echo "Eliminando *.tmp..."
find "$HOME_DIR" -maxdepth 1 -name "*.tmp" -type f -delete -print

# Archivos nano save
echo "Eliminando nano.*.save..."
find "$HOME_DIR" -maxdepth 1 -name "nano.*.save" -type f -delete -print

# bash_history backups
echo "Eliminando .bash_history-*..."
find "$HOME_DIR" -maxdepth 1 -name ".bash_history-*" -type f -delete -print

# Xauthority (se regenera)
echo "Eliminando .Xauthority..."
rm -fv "$HOME_DIR/.Xauthority"

# xsession-errors
echo "Eliminando .xsession-errors*..."
find "$HOME_DIR" -maxdepth 1 -name ".xsession-errors*" -type f -delete -print

# .dmrc (se regenera)
echo "Eliminando .dmrc..."
rm -fv "$HOME_DIR/.dmrc"

# Archivos vacios en home (opcional, comentado por seguridad)
# echo "Buscando archivos vacios en home..."
# find "$HOME_DIR" -maxdepth 1 -type f -empty -delete -print

echo "=== Limpieza completada ==="

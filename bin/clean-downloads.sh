#!/bin/bash
# clean-downloads.sh - Organiza ~/Downloads en subcarpetas

DL_DIR="$HOME/Downloads"

if [ ! -d "$DL_DIR" ]; then
    echo "Error: No existe ~/Downloads"
    exit 1
fi

# Crear subcarpetas
mkdir -p "$DL_DIR/ISOs" "$DL_DIR/Zips" "$DL_DIR/Videos" "$DL_DIR/Apps" "$DL_DIR/Torrents" "$DL_DIR/Otros"

echo "=== Organizando Downloads ==="

# Imagenes → directo a ~/Pictures/
echo "Moviendo imagenes a ~/Pictures/..."
for f in "$DL_DIR"/*.png "$DL_DIR"/*.jpg "$DL_DIR"/*.jpeg "$DL_DIR"/*.webp; do
    [ -e "$f" ] || continue
    mv -v "$f" "$HOME/Pictures/"
done

# ISOs
echo "Moviendo ISOs..."
for f in "$DL_DIR"/*.iso; do
    [ -e "$f" ] || continue
    mv -v "$f" "$DL_DIR/ISOs/"
done

# Comprimidos
echo "Moviendo comprimidos..."
for f in "$DL_DIR"/*.zip "$DL_DIR"/*.tar.gz "$DL_DIR"/*.tar.xz "$DL_DIR"/*.rar "$DL_DIR"/*.tgz; do
    [ -e "$f" ] || continue
    mv -v "$f" "$DL_DIR/Zips/"
done

# Videos
echo "Moviendo videos..."
for f in "$DL_DIR"/*.mp4 "$DL_DIR"/*.mkv "$DL_DIR"/*.webm "$DL_DIR"/*.avi; do
    [ -e "$f" ] || continue
    mv -v "$f" "$DL_DIR/Videos/"
done

# Apps
echo "Moviendo aplicaciones..."
for f in "$DL_DIR"/*.AppImage "$DL_DIR"/*.jar "$DL_DIR"/*.exe "$DL_DIR"/*.flatpak; do
    [ -e "$f" ] || continue
    mv -v "$f" "$DL_DIR/Apps/"
done

# Torrents
echo "Moviendo torrents..."
for f in "$DL_DIR"/*.torrent; do
    [ -e "$f" ] || continue
    mv -v "$f" "$DL_DIR/Torrents/"
done

# Resto a Otros (archivos, no carpetas)
echo "Moviendo resto a Otros..."
for f in "$DL_DIR"/*; do
    [ -e "$f" ] || continue
    [ -d "$f" ] && continue
    # Saltar carpetas creadas por el script
    case "$(basename "$f")" in
        ISOs|Zips|Videos|Apps|Torrents|Otros) continue ;;
    esac
    mv -v "$f" "$DL_DIR/Otros/"
done

echo "=== Limpieza de Downloads completada ==="

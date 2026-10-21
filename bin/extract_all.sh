#!/bin/bash

OUT="extracted"
TMP="tmp_zip"

mkdir -p "$OUT"

for zip in *.zip; do
  echo "Procesando $zip"

  rm -rf "$TMP"
  mkdir "$TMP"

  unzip -q "$zip" -d "$TMP"

  find "$TMP" -type f | while read file; do
    name=$(basename "$file")
    hash=$(sha256sum "$file" | awk '{print $1}')

    target="$OUT/$name"

    if [ -f "$target" ]; then
      existing_hash=$(sha256sum "$target" | awk '{print $1}')

      if [ "$hash" = "$existing_hash" ]; then
        echo "Duplicado real: $name (skip)"
        continue
      else
        ext="${name##*.}"
        base="${name%.*}"
        newname="${base}_${hash:0:8}.$ext"
        echo "Colisión: guardo como $newname"
        cp "$file" "$OUT/$newname"
      fi
    else
      cp "$file" "$target"
    fi
  done
done

rm -rf "$TMP"

echo "Listo."
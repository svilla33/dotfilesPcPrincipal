#!/bin/bash

ORIGEN="$1"
DESTINO="$2"

if [[ -z "$ORIGEN" || -z "$DESTINO" ]]; then
    echo "Uso: $0 /ruta/origen /ruta/destino"
    exit 1
fi

# Archivo temporal para hashes ya vistos
HASH_DB="/tmp/hashes_organizador.txt"
touch "$HASH_DB"

find "$ORIGEN" -type f | while read -r archivo; do
    echo "Procesando: $archivo"

    # Calcular hash
    hash=$(sha256sum "$archivo" | awk '{print $1}')

    # Verificar si ya existe
    if grep -q "^$hash" "$HASH_DB"; then
        echo "  -> Duplicado, se omite"
        continue
    fi

    # Guardar hash
    echo "$hash" >> "$HASH_DB"

    # Obtener año
    anio=$(date -r "$archivo" +%Y)

    # Crear carpeta destino
    carpeta="$DESTINO/$anio"
    mkdir -p "$carpeta"

    # Copiar archivo
    rsync -a "$archivo" "$carpeta/"

done

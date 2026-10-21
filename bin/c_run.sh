#!/bin/bash

# Verificar si se proporcionó el nombre del archivo
if [ $# -eq 0 ]; then
    echo "Error: Debes proporcionar el nombre del archivo C."
    echo "Uso: ./run_c.sh archivo.c"
    exit 1
fi

# Obtener el nombre del archivo sin la extensión
filename=$(basename -- "$1")
filename_without_ext="${filename%.*}"

# Compilar el archivo C
gcc "$1" -o "$filename_without_ext"

# Verificar si la compilación fue exitosa
if [ $? -eq 0 ]; then
    echo "Compilación exitosa. Limpiando la consola y ejecutando el programa..."

    # Limpiar la consola
    clear

    # Ejecutar el programa
    ./"$filename_without_ext"
else
    echo "Error en la compilación."
fi

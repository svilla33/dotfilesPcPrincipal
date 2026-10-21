#!/bin/bash

palabra="${1:-invierno}"

curl -s "https://es.wiktionary.org/w/api.php?action=query&prop=extracts&explaintext=1&titles=$palabra&format=json&redirects=1" \
| jq -r '.query.pages[].extract' \
| awk '
/=== Sustantivo/ {
    in_def=1
    next
}

/===/ && in_def {
    exit
}

in_def && /^[0-9]+( .*)?$/ {

    # Caso: "1 Estaciones"
    linea=$0
    sub(/^[0-9]+ ?/, "", linea)

    if (linea != "") {
        getline
        print "- " $0
    }

    # Caso:
    # 2
    # Definición...
    else {
        getline
        print "- " $0
    }
}
'

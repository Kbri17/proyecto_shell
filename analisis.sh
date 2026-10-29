#!/bin/bash
# =============================================================
# Modulo 3 - Analisis de informacion (analisis.sh)
# =============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATOS="${1:-$DIR/servidores.txt}"
UMBRAL="${2:-70}"
COPIA="$DIR/servidores_copia.txt"
REPORTE="$DIR/reporte_analisis.txt"


if [ ! -f "$DATOS" ]; then
    echo "ERROR: no existe el archivo de datos: $DATOS" >&2; exit 1
fi
if ! [[ "$UMBRAL" =~ ^[0-9]+$ ]]; then
    echo "ERROR: el umbral debe ser un numero entero" >&2; exit 1
fi

{
    echo "Servidores con uso de disco superior a ${UMBRAL}%:"
    awk -F',' -v u="$UMBRAL" 'NR>1 && $3+0>u {printf "  %-12s %-12s %3d%%\n", $1, $2, $3; n++}
        END {print "Total: " n+0 " servidor(es)"}' "$DATOS"
} | tee "$REPORTE"

cp "$DATOS" "$COPIA"
sed -i -e 's/Critico/URGENTE/g' -e 's/Alerta/REVISAR/g' -e 's/Normal/OK/g' "$COPIA"

echo
echo "Copia con palabras reemplazadas (Critico->URGENTE, Alerta->REVISAR, Normal->OK):"
cat "$COPIA"

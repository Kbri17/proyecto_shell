#!/bin/bash
# =============================================================
# Modulo 1 - Monitoreo del sistema (sistema.sh)
# =============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SALIDA="${1:-$DIR/reporte_sistema.txt}"


USUARIO=$(whoami)
FECHA=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)

if [ -r /etc/os-release ]; then
    DISTRO=$(. /etc/os-release && echo "$PRETTY_NAME")
else
    DISTRO="$(uname -s) $(uname -r) (no se encontro /etc/os-release)"
fi

if ! touch "$SALIDA" 2>/dev/null; then
    echo "ERROR: no se puede escribir en $SALIDA" >&2
    exit 1
fi

{
    echo "=========================================="
    echo "      REPORTE DEL SISTEMA"
    echo "=========================================="
    echo "Usuario actual : $USUARIO"
    echo "Equipo         : $HOST"
    echo "Fecha y hora   : $FECHA"
    echo "Distribucion   : $DISTRO"
    echo "------------------------------------------"
    echo "Espacio en disco:"
    df -h
    echo "=========================================="
} > "$SALIDA"

cat "$SALIDA"
echo
echo "Reporte guardado en: $SALIDA"

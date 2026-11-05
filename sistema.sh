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

# CPU: modelo y porcentaje de uso (100 - %idle de top)
CPU_MODELO=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ *//')
CPU_MODELO="${CPU_MODELO:-desconocido}"
CPU_USO=$(top -bn1 | awk '/Cpu\(s\)/ {for(i=1;i<=NF;i++) if($i ~ /id,?$/) {print 100-$(i-1); exit}}')
CPU_USO="${CPU_USO:-N/D}"

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
    echo "Espacio en disco (solo raiz /):"
    df -h /
    echo "------------------------------------------"
    echo "Memoria:"
    free -h
    echo "------------------------------------------"
    echo "CPU:"
    echo "Modelo         : $CPU_MODELO"
    echo "Nucleos        : $(nproc)"
    echo "Uso actual     : ${CPU_USO}%"
    echo "Carga promedio : $(cut -d' ' -f1-3 /proc/loadavg)"
    echo "=========================================="
} > "$SALIDA"

cat "$SALIDA"
echo
echo "Reporte guardado en: $SALIDA"

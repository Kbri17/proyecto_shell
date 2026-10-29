#!/bin/bash
# =============================================================
# Modulo 4 - Automatizacion y reportes (automatizar.sh)
# =============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/automatizar.sh"
MARCA="# monitoreo-diario-idat"

case "$1" in
    --cron)
        if ! command -v crontab >/dev/null; then
            echo "ERROR: crontab no esta disponible en este sistema" >&2; exit 1
        fi
        # Evita duplicar la linea si ya existe
        ( crontab -l 2>/dev/null | grep -v "$MARCA"
          echo "0 7 * * * $SCRIPT >> $DIR/cron.log 2>&1 $MARCA" ) | crontab -
        echo "Tarea programada: todos los dias a las 07:00"
        crontab -l | grep "$MARCA"
        ;;
    --quitar)
        crontab -l 2>/dev/null | grep -v "$MARCA" | crontab -
        echo "Tarea de cron eliminada."
        ;;
    "")
        mkdir -p "$DIR/reportes"
        ARCHIVO="$DIR/reportes/reporte_$(date +%Y-%m-%d_%H%M).txt"
        {
            echo "Fecha de ejecucion: $(date '+%Y-%m-%d %H:%M:%S')"
            echo
            "$DIR/sistema.sh" "$DIR/reporte_sistema.txt"
            echo
            "$DIR/analisis.sh"
        } > "$ARCHIVO" 2>&1
        echo "Reporte generado: $ARCHIVO"
        ;;
    *)
        echo "Uso: $0 [--cron | --quitar]" >&2; exit 1
        ;;
esac

#!/bin/bash
# =============================================================
# Modulo 4 - Automatizacion y reportes (automatizar.sh)
#
# Permite ELEGIR que tareas automatizar y con que FRECUENCIA.
#
# Uso:
#   ./automatizar.sh                           ejecuta todas las tareas ahora
#   ./automatizar.sh --tareas sistema,analisis ejecuta solo las tareas elegidas
#   ./automatizar.sh --cron                    asistente: elegir tareas y frecuencia
#   ./automatizar.sh --listar                  muestra lo programado en cron
#   ./automatizar.sh --quitar [tarea]          quita una tarea (o todas)
#   ./automatizar.sh --ayuda                   muestra esta ayuda
#
# Tareas disponibles: sistema, analisis, limpieza
# =============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/automatizar.sh"
PREF="# auto-idat:"            # cada linea de cron termina en "# auto-idat:<tarea>"
TAREAS_DISPONIBLES=(sistema analisis limpieza)
DIAS_REPORTES=7               # la tarea limpieza borra reportes mas viejos que esto

uso() {
    sed -n '3,17p' "$SCRIPT" | sed 's/^# \{0,1\}//'
}

descripcion() {
    case "$1" in
        sistema)  echo "Reporte del sistema (disco, memoria, CPU)" ;;
        analisis) echo "Analisis de servidores con awk y sed" ;;
        limpieza) echo "Elimina reportes con mas de $DIAS_REPORTES dias" ;;
    esac
}

tarea_valida() {
    local t
    for t in "${TAREAS_DISPONIBLES[@]}"; do
        [ "$t" == "$1" ] && return 0
    done
    return 1
}

# ---------- Ejecucion de tareas ----------
ejecutar_tarea() {
    case "$1" in
        sistema)  "$DIR/sistema.sh" "$DIR/reporte_sistema.txt" ;;
        analisis) "$DIR/analisis.sh" ;;
        limpieza)
            local n
            n=$(find "$DIR/reportes" -maxdepth 1 -name 'reporte_*.txt' -mtime +"$DIAS_REPORTES" 2>/dev/null | wc -l | tr -d ' ')
            find "$DIR/reportes" -maxdepth 1 -name 'reporte_*.txt' -mtime +"$DIAS_REPORTES" -delete 2>/dev/null
            echo "Reportes eliminados (mas de $DIAS_REPORTES dias): $n"
            ;;
    esac
}

ejecutar() {
    mkdir -p "$DIR/reportes"
    local archivo="$DIR/reportes/reporte_$(date +%Y-%m-%d_%H%M%S).txt" t
    {
        echo "Fecha de ejecucion: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Tareas: $*"
        for t in "$@"; do
            echo
            echo "########## Tarea: $t ##########"
            ejecutar_tarea "$t"
        done
    } > "$archivo" 2>&1
    echo "Reporte generado: $archivo"
}

# ---------- Asistente de programacion ----------
entero_en_rango() {   # entero_en_rango valor minimo maximo
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$((10#$1))" -ge "$2" ] && [ "$((10#$1))" -le "$3" ]
}

pedir_hora() {        # deja HORA y MIN
    local h
    read -r -p "Hora (HH:MM, formato 24h): " h || return 1
    if [[ "$h" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
        HORA=$((10#${BASH_REMATCH[1]})); MIN=$((10#${BASH_REMATCH[2]}))
    else
        echo "Hora invalida (ej. 07:30)."; return 1
    fi
}

elegir_tareas() {     # deja SELECCION
    local t r
    SELECCION=()
    echo "Tareas disponibles (responda s/n para automatizar):"
    for t in "${TAREAS_DISPONIBLES[@]}"; do
        read -r -p "  $t - $(descripcion "$t")? (s/n): " r || return 1
        [[ "$r" == [sS] ]] && SELECCION+=("$t")
    done
    if [ ${#SELECCION[@]} -eq 0 ]; then
        echo "No selecciono ninguna tarea."; return 1
    fi
}

elegir_frecuencia() { # deja CRON_EXPR y FREC_TXT
    local op n dia
    echo "Frecuencia:"
    echo "  1) Cada N minutos"
    echo "  2) Cada hora"
    echo "  3) Diaria"
    echo "  4) Semanal"
    echo "  5) Mensual"
    read -r -p "Opcion: " op || return 1
    case "$op" in
        1)  read -r -p "Cada cuantos minutos (1-59): " n || return 1
            entero_en_rango "$n" 1 59 || { echo "Valor invalido (1-59)."; return 1; }
            n=$((10#$n))
            CRON_EXPR="*/$n * * * *"; FREC_TXT="cada $n minuto(s)" ;;
        2)  CRON_EXPR="0 * * * *"; FREC_TXT="cada hora (en el minuto 0)" ;;
        3)  pedir_hora || return 1
            CRON_EXPR="$MIN $HORA * * *"
            FREC_TXT="todos los dias a las $(printf '%02d:%02d' "$HORA" "$MIN")" ;;
        4)  read -r -p "Dia de la semana (0=domingo, 1=lunes ... 6=sabado): " dia || return 1
            entero_en_rango "$dia" 0 6 || { echo "Dia invalido (0-6)."; return 1; }
            dia=$((10#$dia)); pedir_hora || return 1
            CRON_EXPR="$MIN $HORA * * $dia"
            FREC_TXT="cada semana (dia $dia) a las $(printf '%02d:%02d' "$HORA" "$MIN")" ;;
        5)  read -r -p "Dia del mes (1-28): " dia || return 1
            entero_en_rango "$dia" 1 28 || { echo "Dia invalido (1-28)."; return 1; }
            dia=$((10#$dia)); pedir_hora || return 1
            CRON_EXPR="$MIN $HORA $dia * *"
            FREC_TXT="el dia $dia de cada mes a las $(printf '%02d:%02d' "$HORA" "$MIN")" ;;
        *)  echo "Opcion invalida."; return 1 ;;
    esac
}

programar() {
    if ! command -v crontab >/dev/null; then
        echo "ERROR: crontab no esta disponible en este sistema" >&2; exit 1
    fi
    elegir_tareas    || exit 1
    elegir_frecuencia || exit 1

    local tmp t
    tmp=$(mktemp)
    crontab -l 2>/dev/null > "$tmp"
    for t in "${SELECCION[@]}"; do
        # Reemplaza la linea anterior de esa tarea (evita duplicados)
        grep -v "$PREF$t\$" "$tmp" > "$tmp.n"; mv "$tmp.n" "$tmp"
        echo "$CRON_EXPR $SCRIPT --tareas $t >> $DIR/cron.log 2>&1 $PREF$t" >> "$tmp"
    done
    crontab "$tmp"; rm -f "$tmp"

    echo
    echo "Tarea(s) programada(s) ${FREC_TXT}: ${SELECCION[*]}"
    listar
}

listar() {
    local lineas l t e
    lineas=$(crontab -l 2>/dev/null | grep "$PREF")
    if [ -z "$lineas" ]; then
        echo "No hay tareas programadas por este script."; return
    fi
    echo "Tareas programadas (minuto hora dia mes dia_semana):"
    while IFS= read -r l; do
        t=$(sed "s/.*$PREF//" <<< "$l")
        e=$(cut -d' ' -f1-5 <<< "$l")
        printf "  %-10s %s\n" "$t" "$e"
    done <<< "$lineas"
}

quitar() {
    local objetivo="$1" tmp
    if [ -n "$objetivo" ] && ! tarea_valida "$objetivo"; then
        echo "ERROR: tarea desconocida '$objetivo' (disponibles: ${TAREAS_DISPONIBLES[*]})" >&2; exit 1
    fi
    tmp=$(mktemp)
    crontab -l 2>/dev/null > "$tmp"
    if [ -z "$objetivo" ]; then
        grep -v "$PREF" "$tmp" > "$tmp.n"
    else
        grep -v "$PREF$objetivo\$" "$tmp" > "$tmp.n"
    fi
    crontab "$tmp.n"; rm -f "$tmp" "$tmp.n"
    echo "Tarea(s) eliminada(s) de cron: ${objetivo:-todas}"
}

# ---------- Principal ----------
case "${1:-}" in
    "")
        ejecutar "${TAREAS_DISPONIBLES[@]}"
        ;;
    --tareas)
        if [ -z "${2:-}" ]; then
            echo "ERROR: indique las tareas, ej. --tareas sistema,analisis" >&2; exit 1
        fi
        IFS=',' read -r -a ELEGIDAS <<< "$2"
        for t in "${ELEGIDAS[@]}"; do
            tarea_valida "$t" || { echo "ERROR: tarea desconocida '$t' (disponibles: ${TAREAS_DISPONIBLES[*]})" >&2; exit 1; }
        done
        ejecutar "${ELEGIDAS[@]}"
        ;;
    --cron)    programar ;;
    --listar)  listar ;;
    --quitar)  quitar "${2:-}" ;;
    --ayuda|-h) uso ;;
    *)
        echo "ERROR: opcion desconocida '$1'" >&2
        uso >&2; exit 1
        ;;
esac

#!/bin/bash
# =============================================================
# Modulo 3 - Analisis de informacion (analisis.sh)
#
# Uso: ./analisis.sh [-a ambiente] [-h] [archivo] [umbral]
#   archivo   CSV con: servidor,ambiente,uso_disco,estado (def. servidores.txt)
#   umbral    entero 0-100 para marcar servidores en riesgo (def. 70)
#   -a AMB    analiza solo un ambiente (produccion, desarrollo, pruebas...)
# =============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPIA="$DIR/servidores_copia.txt"
REPORTE="$DIR/reporte_analisis.txt"
AMBIENTE=""

uso() {
    echo "Uso: $0 [-a ambiente] [archivo] [umbral]"
    echo "  Ej.: $0                       # servidores.txt, umbral 70"
    echo "       $0 servidores.txt 80     # umbral 80"
    echo "       $0 -a produccion         # solo el ambiente produccion"
}

while getopts ":a:h" opt; do
    case "$opt" in
        a) AMBIENTE="$OPTARG" ;;
        h) uso; exit 0 ;;
        :) echo "ERROR: la opcion -$OPTARG necesita un valor" >&2; exit 1 ;;
        *) echo "ERROR: opcion invalida -$OPTARG" >&2; uso >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

DATOS="${1:-$DIR/servidores.txt}"
UMBRAL="${2:-70}"

if [ ! -f "$DATOS" ]; then
    echo "ERROR: no existe el archivo de datos: $DATOS" >&2; exit 1
fi
if ! [[ "$UMBRAL" =~ ^[0-9]+$ ]] || [ "$UMBRAL" -gt 100 ]; then
    echo "ERROR: el umbral debe ser un numero entero entre 0 y 100" >&2; exit 1
fi

{
    echo "=========================================="
    echo "      ANALISIS DE SERVIDORES"
    echo "=========================================="
    echo "Archivo  : $DATOS"
    echo "Umbral   : ${UMBRAL}%"
    echo "Ambiente : ${AMBIENTE:-todos}"
    echo "Fecha    : $(date '+%Y-%m-%d %H:%M:%S')"

    awk -F',' -v u="$UMBRAL" -v amb="$AMBIENTE" '
    function barra(p,   i, s) {
        s = ""
        for (i = 0; i < int(p / 5); i++) s = s "#"
        return s
    }
    BEGIN { n = 0; m = 0; malas = 0 }
    NR == 1 { next }
    $0 ~ /^[ \t\r]*$/ { next }
    {
        sub(/\r$/, "")
        # Descarta lineas con formato incorrecto
        if (NF < 4 || $3 !~ /^[0-9]+$/ || $3 + 0 > 100) { malas++; next }
        if (amb != "" && $2 != amb) next

        n++; suma += $3
        if (n == 1 || $3 + 0 > max) { max = $3 + 0; smax = $1 }
        if (n == 1 || $3 + 0 < min) { min = $3 + 0; smin = $1 }

        est[$4]++
        an[$2]++; as[$2] += $3
        if ($3 + 0 > am[$2]) am[$2] = $3 + 0

        if ($3 + 0 > u) {
            m++
            r_srv[m] = $1; r_amb[m] = $2; r_uso[m] = $3 + 0; r_est[m] = $4
        }
    }
    END {
        if (n == 0) {
            print "\nNo hay datos validos para analizar."
            if (malas > 0) print "Lineas descartadas por formato incorrecto: " malas
            exit
        }

        print "\n--- Resumen general ---"
        printf "Servidores analizados : %d\n", n
        printf "Uso promedio          : %.1f%%\n", suma / n
        printf "Mayor uso             : %s (%d%%)\n", smax, max
        printf "Menor uso             : %s (%d%%)\n", smin, min
        printf "Sobre el umbral       : %d de %d (%.1f%%)\n", m, n, m * 100 / n
        if (malas > 0) printf "Lineas descartadas    : %d (formato incorrecto)\n", malas

        # Claves ordenadas alfabeticamente (insercion)
        ne = 0; for (k in est) ke[++ne] = k
        for (i = 2; i <= ne; i++) { t = ke[i]; j = i - 1; while (j > 0 && ke[j] > t) { ke[j+1] = ke[j]; j-- } ke[j+1] = t }
        na = 0; for (k in an) ka[++na] = k
        for (i = 2; i <= na; i++) { t = ka[i]; j = i - 1; while (j > 0 && ka[j] > t) { ka[j+1] = ka[j]; j-- } ka[j+1] = t }

        print "\n--- Por estado ---"
        for (i = 1; i <= ne; i++)
            printf "  %-10s %2d  %-20s %5.1f%%\n", ke[i], est[ke[i]], barra(est[ke[i]] * 100 / n), est[ke[i]] * 100 / n

        print "\n--- Por ambiente ---"
        printf "  %-12s %9s %9s %7s\n", "Ambiente", "Servidores", "Promedio", "Maximo"
        for (i = 1; i <= na; i++)
            printf "  %-12s %9d %8.1f%% %6d%%\n", ka[i], an[ka[i]], as[ka[i]] / an[ka[i]], am[ka[i]]

        # Ranking de mayor a menor uso
        for (i = 1; i <= m; i++) ix[i] = i
        for (i = 2; i <= m; i++) { t = ix[i]; j = i - 1; while (j > 0 && r_uso[ix[j]] < r_uso[t]) { ix[j+1] = ix[j]; j-- } ix[j+1] = t }

        printf "\n--- Servidores con uso de disco superior a %d%% (mayor a menor) ---\n", u
        if (m == 0) print "  Ninguno."
        for (i = 1; i <= m; i++) {
            k = ix[i]
            printf "  %2d. %-12s %-11s %3d%%  %-20s %s\n", i, r_srv[k], r_amb[k], r_uso[k], barra(r_uso[k]), r_est[k]
        }
        print "Total: " m " servidor(es)"
    }' "$DATOS"
} | tee "$REPORTE"

# Copia del archivo con palabras reemplazadas (el original no se modifica)
sed -e 's/Critico/URGENTE/g' -e 's/Alerta/REVISAR/g' -e 's/Normal/OK/g' "$DATOS" > "$COPIA"

echo
echo "Copia con palabras reemplazadas (Critico->URGENTE, Alerta->REVISAR, Normal->OK):"
cat "$COPIA"

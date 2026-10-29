#!/bin/bash
# =============================================================
# Modulo 2 - Gestion de archivos (gestor.sh)
# =============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRUEBAS="$DIR/pruebas"
mkdir -p "$PRUEBAS"

nombre_valido() {
    [[ -n "$1" && "$1" != */* && "$1" != .* ]]
}

crear_archivo() {
    read -r -p "Nombre del archivo a crear: " nombre
    if ! nombre_valido "$nombre"; then
        echo "Nombre invalido."; return
    fi
    if [ -e "$PRUEBAS/$nombre" ]; then
        echo "El archivo ya existe."
    else
        echo "Archivo de prueba creado el $(date)" > "$PRUEBAS/$nombre"
        echo "Archivo creado: $PRUEBAS/$nombre"
    fi
}

copiar_archivo() {
    read -r -p "Archivo origen: " origen
    read -r -p "Nombre de la copia: " destino
    if ! nombre_valido "$origen" || ! nombre_valido "$destino"; then
        echo "Nombre invalido."; return
    fi
    if [ ! -f "$PRUEBAS/$origen" ]; then
        echo "El archivo origen no existe."
    elif [ -e "$PRUEBAS/$destino" ]; then
        echo "El destino ya existe, no se sobrescribe."
    else
        cp "$PRUEBAS/$origen" "$PRUEBAS/$destino" && echo "Copiado: $origen -> $destino"
    fi
}

cambiar_permisos() {
    read -r -p "Archivo al que aplicar permisos 644: " nombre
    if ! nombre_valido "$nombre" || [ ! -f "$PRUEBAS/$nombre" ]; then
        echo "El archivo no existe."; return
    fi
    chmod 644 "$PRUEBAS/$nombre" && echo "Permisos actuales:" && ls -l "$PRUEBAS/$nombre"
}

eliminar_archivo() {
    read -r -p "Archivo a eliminar: " nombre
    if ! nombre_valido "$nombre" || [ ! -f "$PRUEBAS/$nombre" ]; then
        echo "El archivo no existe."; return
    fi
    read -r -p "Seguro que desea eliminar $nombre? (s/n): " resp
    case "$resp" in
        s|S) rm "$PRUEBAS/$nombre" && echo "Archivo eliminado." ;;
        *)   echo "Operacion cancelada." ;;
    esac
}


eliminar_por_fecha() {
    read -r -p "Eliminar archivos anteriores a (AAAA-MM-DD): " fecha
    if ! [[ "$fecha" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! date -d "$fecha" >/dev/null 2>&1; then
        echo "Fecha invalida."; return
    fi
    # find: archivos que NO son mas nuevos que la fecha = anteriores
    mapfile -t lista < <(find "$PRUEBAS" -maxdepth 1 -type f ! -newermt "$fecha")
    if [ ${#lista[@]} -eq 0 ]; then
        echo "No hay archivos anteriores a $fecha."; return
    fi
    echo "Se eliminaran:"
    printf '  %s\n' "${lista[@]##*/}"
    read -r -p "Confirmar? (s/n): " resp
    if [[ "$resp" == [sS] ]]; then
        rm -f "${lista[@]}" && echo "${#lista[@]} archivo(s) eliminado(s)."
    else
        echo "Operacion cancelada."
    fi
}

listar() {
    echo "Contenido de $PRUEBAS:"
    ls -l "$PRUEBAS"
}

opcion=""
while [ "$opcion" != "0" ]; do
    echo
    echo "===== GESTOR DE ARCHIVOS ====="
    echo "1) Crear archivo"
    echo "2) Copiar archivo"
    echo "3) Cambiar permisos a 644"
    echo "4) Eliminar archivo (con confirmacion)"
    echo "5) Eliminar archivos por fecha"
    echo "6) Listar archivos"
    echo "0) Salir"
    read -r -p "Opcion: " opcion || break
    case "$opcion" in
        1) crear_archivo ;;
        2) copiar_archivo ;;
        3) cambiar_permisos ;;
        4) eliminar_archivo ;;
        5) eliminar_por_fecha ;;
        6) listar ;;
        0) echo "Hasta luego." ;;
        *) echo "Opcion invalida, intente de nuevo." ;;
    esac
done

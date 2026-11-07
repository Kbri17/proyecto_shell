# Proyecto Shell Scripting

Conjunto de scripts en Bash para automatizar tareas básicas de administración de servidores Linux: revisar el estado del sistema, gestionar archivos, generar reportes y programar tareas.

Proyecto de la evaluación parcial del curso Shell Scripting (IDAT).

## Problema

El área de TI de una empresa mediana realiza de forma manual tareas como revisar el uso de disco, organizar archivos y generar reportes. Esto aumenta el riesgo de errores y demora las operaciones. Este proyecto las automatiza con scripts reutilizables.

## Qué incluye

| Script | Qué hace |
|---|---|
| `sistema.sh` | Muestra información del sistema: usuario, distribución, disco, memoria y CPU. |
| `gestor.sh` | Gestiona archivos: crea, copia, cambia permisos y elimina, incluso por fecha. |
| `analisis.sh` | Genera un reporte de servidores con `awk` y reemplaza palabras con `sed`. |
| `automatizar.sh` | Ejecuta las tareas, genera reportes y las programa en `cron`. |
| `servidores.txt` | Datos de ejemplo (CSV) para `analisis.sh`. |

## Tecnologías

Bash, estructuras de control (`if`, `case`, `for`, `while`), funciones, redirección, `cron`, `awk`, `sed` y Git. Probado en Ubuntu 24.04.

## Requisitos e instalación

- Linux con Bash y utilidades GNU (`awk`, `sed`, `find`, `date`, `top`, `free`).
- `crontab` (paquete `cron`) para programar tareas.

```bash
cd proyecto_shell
chmod +x *.sh
```

---

## Uso de cada script

### sistema.sh

Muestra usuario, equipo, fecha, distribución, disco (`/`), memoria y CPU, y guarda el reporte en un archivo.

```bash
./sistema.sh [ruta_salida]
```

| Parámetro | Descripción | Por defecto |
|---|---|---|
| `ruta_salida` | Archivo donde se guarda el reporte | `reporte_sistema.txt` |

```bash
./sistema.sh                      # guarda en reporte_sistema.txt
./sistema.sh /tmp/mi_reporte.txt  # guarda en otra ruta
./sistema.sh /root/x.txt          # sin permisos: ERROR y exit 1
```

### gestor.sh

Menú interactivo, sin parámetros. Trabaja solo dentro de la carpeta `pruebas/` (se crea sola).

```bash
./gestor.sh
```

| Opción | Acción | Validaciones |
|---|---|---|
| 1 | Crear archivo | Nombre sin `/` ni punto inicial; no sobrescribe |
| 2 | Copiar archivo | El origen debe existir; no sobrescribe el destino |
| 3 | Cambiar permisos | 3 dígitos del 0 al 7; explica cada permiso |
| 4 | Eliminar archivo | Pide confirmación (s/n) |
| 5 | Eliminar por fecha | Formato `AAAA-MM-DD`; lista los archivos y pide confirmación |
| 6 | Listar archivos | Muestra el contenido de `pruebas/` |
| 0 | Salir | |

Ejemplo (opción 3):

```
Archivo al que cambiar permisos: demo.txt
Nuevos permisos (3 digitos, ej. 644, 600, 755): 644
  Dueno  : leer, escribir
  Grupo  : leer
  Otros  : leer
```

Permisos: `r`=4 (leer), `w`=2 (escribir), `x`=1 (ejecutar), sumados por bloque (dueño, grupo, otros). Ejemplo: `644` = `rw-r--r--`.

### analisis.sh

Lee un CSV (`servidor,ambiente,uso_disco,estado`) y con `awk` genera: promedio, mayor y menor uso, conteo por estado y por ambiente, y un ranking de servidores sobre el umbral. Con `sed` crea una copia con palabras reemplazadas (`Critico`→`URGENTE`, `Alerta`→`REVISAR`, `Normal`→`OK`); el original no se modifica.

```bash
./analisis.sh [-a ambiente] [-h] [archivo] [umbral]
```

| Parámetro | Descripción | Por defecto |
|---|---|---|
| `-a ambiente` | Analiza solo un ambiente (produccion, desarrollo, pruebas) | todos |
| `-h` | Muestra la ayuda | |
| `archivo` | CSV de entrada | `servidores.txt` |
| `umbral` | Entero de 0 a 100 | `70` |

Las opciones (`-a`, `-h`) van antes del archivo y del umbral.

```bash
./analisis.sh                                  # umbral 70
./analisis.sh servidores.txt 80                # umbral 80
./analisis.sh -a produccion servidores.txt 80  # solo producción
./analisis.sh servidores.txt 150               # ERROR: umbral fuera de rango
```

Genera `reporte_analisis.txt` y `servidores_copia.txt`.

### automatizar.sh

Ejecuta las tareas `sistema`, `analisis` y `limpieza` (borra reportes de más de 7 días), guarda el resultado en `reportes/reporte_FECHA_HORA.txt` y permite programarlas en cron.

```bash
./automatizar.sh [--tareas lista | --cron | --listar | --quitar [tarea] | --ayuda]
```

| Opción | Descripción |
|---|---|
| *(sin opción)* | Ejecuta todas las tareas ahora |
| `--tareas a,b` | Ejecuta solo las tareas indicadas |
| `--cron` | Asistente: elige tareas y frecuencia (cada N minutos, hora, diaria, semanal o mensual) |
| `--listar` | Muestra lo programado en cron por este script |
| `--quitar [tarea]` | Quita una tarea, o todas si no se indica |
| `--ayuda` | Muestra el uso |

```bash
./automatizar.sh                            # todas las tareas
./automatizar.sh --tareas sistema,analisis  # solo esas dos
./automatizar.sh --cron                     # programar (asistente)
./automatizar.sh --listar                   # ver lo programado
./automatizar.sh --quitar limpieza          # quitar una tarea
./automatizar.sh --quitar                   # quitar todas
```

Cada línea de cron termina con la marca `# auto-idat:<tarea>`: programar de nuevo reemplaza la línea anterior (sin duplicados) y `--quitar` solo toca las líneas de este script. La salida de cron se guarda en `cron.log`.

Formato de cron: `minuto hora día mes día_semana`. Ejemplo: `0 7 * * *` = todos los días a las 07:00.

---

## Archivos generados

| Archivo / carpeta | Lo crea |
|---|---|
| `reporte_sistema.txt` | `sistema.sh` |
| `reporte_analisis.txt`, `servidores_copia.txt` | `analisis.sh` |
| `pruebas/` | `gestor.sh` |
| `reportes/`, `cron.log` | `automatizar.sh` |

## Limitaciones y mejoras

- `gestor.sh` solo opera dentro de `pruebas/`.
- Los datos de `servidores.txt` son estáticos.
- Requiere `crontab` y utilidades GNU.
- Mejoras: alertas por correo desde cron, log centralizado y lectura del uso de disco real de varios servidores.

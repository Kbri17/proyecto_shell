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
| `automatizar.sh` | Programa una tarea en `cron` y genera un reporte diario. |

## Tecnologías

Bash, estructuras de control (`if`, `case`, `for`, `while`), funciones, redirección, `cron`, `awk`, `sed` y Git. Probado en Ubuntu.

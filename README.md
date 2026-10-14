# noctalia-keepass

Plugin de launcher para Noctalia
que busca entradas de tu base KeePass / KeePassXC y copia usuario, contraseña
o código TOTP al portapapeles.

Escribe `/kp` en el launcher, filtra por título, usuario o URL y elige qué
copiar.

Necesita el demonio `kp-daemon` (repositorio aparte), que es quien abre la base.
Este plugin solo muestra los resultados y lanza el demonio cuando hace falta.

## Instalación

1. Instala `kp-daemon` (ver su README) en `/usr/local/bin` o donde prefieras.
2. Copia esta carpeta al directorio de plugins de Noctalia.
3. Edita `finder.luau` y ajusta, en la sección de configuración:
   - `DAEMON`: ruta del binario.
   - `DB`: ruta de tu base `.kdbx`.

## Uso

- `/kp`: lista las entradas. Si la base está bloqueada, aparece
  "Base bloqueada"; pulsa Enter y el demonio pedirá la contraseña maestra.
- Selecciona una entrada y elige **Copiar usuario**, **Copiar contraseña** o
  **Copiar TOTP** (solo si la entrada tiene semilla TOTP).
- **Bloquear** (en la lista vacía) cierra el demonio y borra la memoria.

El demonio se bloquea solo tras 15 minutos de inactividad.

## Problemas frecuentes

El demonio escribe su salida en `$XDG_RUNTIME_DIR/kp-daemon.log`. Si pulsas
Enter en "Base bloqueada" y no aparece la ventana de contraseña, mira ahí:

```sh
cat "$XDG_RUNTIME_DIR/kp-daemon.log"
```

Causas típicas: la ruta de `DB` no existe, o faltan `zenity` / `pinentry-qt`.

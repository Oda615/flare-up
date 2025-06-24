# ESPAÑOL/SPANISH

Script en Bash para actualizar registros DNS tipo A en Cloudflare usando tu IP pública actual. Ideal para servidores con IP dinámica como Proxmox, servidores caseros o entornos con conexiones no estáticas.

Este script detecta la IP pública, encuentra automáticamente la zona correspondiente en Cloudflare y actualiza (o crea) los registros A necesarios. También mantiene el estado del proxy y registra las operaciones con marcas de tiempo.


## Requisitos

- bash
- curl
- jq
- Un token de API de Cloudflare con:
  - Zone:Read
  - DNS:Edit

---

## Instalación y uso

1. Clona este repositorio o descarga los archivos:

```bash
git clone https://github.com/tuusuario/flare-up.git
cd flare-up
```

2. Crea un archivo `.env` con tu token de Cloudflare:

```bash
echo "CF_API_TOKEN=tu_token_aqui" > .env
```

3. Edita el archivo `dominios.txt` con tus dominios. Formato por línea:

```
subdominio.dominio.com true
otro.dominio.net false
noproxy.otrodominio.org
```

4. Haz ejecutable el script:

```bash
chmod +x flare-up.sh
```

5. Ejecuta el script manualmente:

```bash
./flare-up.sh
```

---

## Automatización con cron

Para ejecutar automáticamente cada 5 minutos:

```bash
*/5 * * * * /ruta/absoluta/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

## Características

- Detección automática de IP pública
- Soporte para múltiples dominios y zonas
- Crea registros si no existen
- Mantiene el estado del proxy
- Verifica dependencias (`curl`, `jq`)
- Valida el token antes de ejecutar

# INGLES/ENGLISH

# flare-up

Bash script to update A records in Cloudflare using your current public IP. Ideal for servers with dynamic IPs like Proxmox, home servers or remote environments.

This script detects the current public IP, auto-detects the proper DNS zone from Cloudflare, and updates (or creates) the relevant A records. It preserves the proxy state and logs actions with timestamps.

---

## Requirements

- bash
- curl
- jq
- A Cloudflare API Token with:
  - Zone:Read
  - DNS:Edit

---

## Installation and usage

1. Clone this repository or download the files:

```bash
git clone https://github.com/youruser/flare-up.git
cd flare-up
```

2. Create a `.env` file with your Cloudflare token:

```bash
echo "CF_API_TOKEN=your_token_here" > .env
```

3. Edit `dominios.txt` with the domains you want to update. One per line:

```
sub.domain.com true
another.domain.net false
no-proxy.domain.org
```

4. Make the script executable:

```bash
chmod +x flare-up.sh
```

5. Run the script manually:

```bash
./flare-up.sh
```

---

## Automate with cron

To run every 5 minutes:

```bash
*/5 * * * * /full/path/to/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

## Features

- Automatically detects your public IP
- Supports multiple domains and zones
- Creates records if missing
- Preserves Cloudflare proxy settings
- Validates dependencies (`curl`, `jq`)
- Verifies API token before running

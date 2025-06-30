# flare-up

---

## 🇪🇸 ESPAÑOL

Script en Bash para actualizar registros DNS tipo A en Cloudflare usando tu IP pública actual. Ideal para servidores con IP dinámica como Proxmox, servidores caseros o entornos con conexiones no estáticas.

Este script detecta la IP pública, encuentra automáticamente la zona correspondiente en Cloudflare y actualiza (o crea) los registros A necesarios. También mantiene el estado del proxy y registra las operaciones con marcas de tiempo.

---

### Requisitos

- bash
- curl
- jq
- Un token de API de Cloudflare con:
  - Zone:Read
  - DNS:Edit

---

### Instalación y uso

```bash
git clone https://github.com/oda615/flare-up.git
cd flare-up

echo "CF_API_TOKEN=tu_token_aqui" > .env
```

Edita el archivo `dominios.txt` con tus dominios (uno por línea):

```
subdominio.dominio.com true
otro.dominio.net false
noproxy.otrodominio.org
```

```bash
chmod +x flare-up.sh
./flare-up.sh
```

---

### Automatización con cron

```bash
*/5 * * * * /ruta/absoluta/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

### Características

- Detección automática de IP pública
- Soporte para múltiples dominios y zonas
- Crea registros si no existen
- Mantiene el estado del proxy
- Verifica dependencias (`curl`, `jq`)
- Valida el token antes de ejecutar

---

## 🇬🇧 ENGLISH

Bash script to update A records in Cloudflare using your current public IP. Ideal for servers with dynamic IPs like Proxmox, home servers or remote environments.

This script detects the current public IP, auto-detects the proper DNS zone from Cloudflare, and updates (or creates) the relevant A records. It preserves the proxy state and logs actions with timestamps.

---

### Requirements

- bash
- curl
- jq
- A Cloudflare API Token with:
  - Zone:Read
  - DNS:Edit

---

### Installation and usage

```bash
git clone https://github.com/oda615/flare-up.git
cd flare-up

echo "CF_API_TOKEN=your_token_here" > .env
```

Edit `dominios.txt` with the domains you want to update:

```
sub.domain.com true
another.domain.net false
no-proxy.domain.org
```

```bash
chmod +x flare-up.sh
./flare-up.sh
```

---

### Automate with cron

```bash
*/5 * * * * /full/path/to/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

### Features

- Automatically detects your public IP
- Supports multiple domains and zones
- Creates records if missing
- Preserves Cloudflare proxy settings
- Validates dependencies (`curl`, `jq`)
- Verifies API token before running

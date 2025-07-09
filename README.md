# flare-up

---

## 🇪🇸 ESPAÑOL

Script en Bash para actualizar registros DNS tipo A en Cloudflare usando tu IP pública actual. Ideal para servidores con IP dinámica como Proxmox, servidores caseros o entornos con conexiones no estáticas.

Este script detecta la IP pública, encuentra automáticamente la zona correspondiente en Cloudflare y actualiza (o crea) los registros A necesarios. También mantiene el estado del proxy y registra las operaciones con marcas de tiempo.  
Ahora también permite elegir idioma de salida: español o inglés.

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
git clone https://github.com/Oda615/flare-up.git
cd flare-up

cp .env.example .env
nano .env  # Añade tu token y el idioma

Contenido de ejemplo para `.env`:
```env
CF_API_TOKEN=your_cloudflare_api_token_here
LANG=es
```
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
*/5 * * * * /ruta/completa/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

### Características

- Detección automática de IP pública
- Soporte para múltiples dominios y zonas
- Crea registros A si no existen
- Mantiene el estado del proxy
- Mensajes en español o inglés (configurable en `.env`)
- Verifica dependencias (`curl`, `jq`)
- Valida el token antes de ejecutar

---

## 🇬🇧 ENGLISH

Bash script to update A records in Cloudflare using your current public IP. Ideal for servers with dynamic IPs like Proxmox, home servers, or dynamic network environments.

This script detects the current public IP, auto-detects the proper DNS zone from Cloudflare, and updates (or creates) the relevant A records. It also preserves the proxy status and logs operations with timestamps.  
Now supports bilingual output: Spanish or English.

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
git clone https://github.com/Oda615/flare-up.git
cd flare-up

cp .env.example .env
nano .env  # Add your token and language

Example content for `.env`:
```env
CF_API_TOKEN=your_cloudflare_api_token_here
LANG=en
```
```

Edit `dominios.txt` with the domains to update (one per line):

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
*/5 * * * * /full/path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

### Features

- Automatically detects your public IP
- Supports multiple domains and DNS zones
- Creates records if missing
- Preserves Cloudflare proxy settings
- Bilingual messages (Spanish or English via `.env`)
- Validates dependencies (`curl`, `jq`)
- Verifies API token before running

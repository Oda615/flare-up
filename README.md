# flare-up

---

## 🇪🇸 ESPAÑOL

Script en Bash para actualizar registros DNS (A, AAAA, CNAME) en Cloudflare usando tu IP pública actual. Ideal para servidores con IP dinámica como Proxmox, servidores caseros o entornos con conexiones no estáticas.

Este script detecta la IP pública, encuentra automáticamente la zona correspondiente en Cloudflare y actualiza (o crea) los registros necesarios. También mantiene el estado del proxy, permite TTL personalizado, etiquetas, logs y notificaciones opcionales por Discord o Telegram.

---

### Funcionalidades

- Soporte para registros `A`, `AAAA`, `CNAME`
- TTL personalizable por dominio
- Filtro por etiquetas (`main`, `backup`, etc.)
- Logging opcional a archivo (`LOGFILE`)
- Notificaciones opcionales por Discord y Telegram
- Multilenguaje (`LANG=es` o `LANG=en`)
- Validación de dependencias (`jq`, `curl`)
- Detección automática de IP pública (IPv4/IPv6)
- Crea registros si no existen
- Respeta configuración de proxy (`true/false`)

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
nano .env  # Añade tu token y configuración
```

### Ejemplo de `.env`:

```env
CF_API_TOKEN=tu_token_aqui
LANG=es
LOGFILE=/var/log/flare-up.log
FILTER=main
DISCORD_WEBHOOK=
TELEGRAM_TOKEN=
TELEGRAM_CHAT_ID=
```

---


---

### Formato del archivo dominios.txt

Cada línea representa un registro DNS a procesar. El formato general es:

```
tipo subdominio.dominio.com proxy ttl etiqueta
```

### Campos:

- `tipo` (opcional): Puede ser `A`, `AAAA` o `CNAME`. Si se omite, se asume `A`.
- `subdominio.dominio.com` (obligatorio): Nombre completo del subdominio a actualizar.
- `proxy` (opcional): `true` para activar el proxy de Cloudflare, `false` para dejarlo desactivado. Por defecto se asume `false`.
- `ttl` (opcional): Tiempo de vida del registro en segundos (ej. `120`, `300`, `3600`). Si no se indica, se usará el valor por defecto de `300`.
- `etiqueta` (opcional): Permite clasificar los registros para aplicar filtros. Si no se especifica, el registro no tendrá etiqueta.

### Ejemplos válidos:

```
A vpn.ejemplo.com true 120 main
AAAA ipv6.ejemplo.com false 300 backup
CNAME www.ejemplo.com false
archivo.ejemplo.net
```

---



Cada línea representa un dominio a actualizar. Formato completo:

```
tipo sub.dominio.com proxy ttl etiqueta
```

Campos:

- `tipo` (opcional): A, AAAA, CNAME. Si no se especifica, se asume `A`.
- `proxy`: true o false
- `ttl`: tiempo de vida del registro (ej. 120, 300, 3600)
- `etiqueta`: para agrupar y filtrar dominios (ej. main, backup)

### Ejemplos válidos:

```
A vpn.misitio.com true 120 main
AAAA ipv6.misitio.com false 300 backup
CNAME app.misitio.com false
noproxy.otrodominio.org
```

---

### Ejecutar el script

```bash
chmod +x flare-up.sh
./flare-up.sh
```

---


---

### Filtro por etiquetas (`FILTER`)

El script permite asignar **etiquetas** a los dominios en el archivo `dominios.txt`. Estas etiquetas te permiten agrupar dominios por tipo o función (por ejemplo, `main`, `backup`, `monitoring`, etc.).

### ¿Cómo funciona?

En el archivo `dominios.txt`, cada línea puede incluir una **etiqueta al final**:

```
A vpn.tuservidor.com true 120 main
AAAA ipv6.tuservidor.com false 300 backup
CNAME app.tuservidor.com false - monitoring
```

Luego, en el archivo `.env`, puedes definir:

```
FILTER=main
```

Esto hará que **solo se procesen los dominios con la etiqueta `main`**, ignorando los demás.

### ¿Para qué sirve?

- Ejecutar actualizaciones selectivas desde distintos `cron`
- Separar grupos de registros según su rol o prioridad
- Hacer pruebas sin tocar producción (`FILTER=dev`)
- Evitar actualizar todo en cada ejecución

### Ejemplo práctico con `cron`

```
# Actualizar solo los dominios principales cada 5 minutos
*/5 * * * * FILTER=main /ruta/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1

# Actualizar solo los dominios de respaldo cada hora
0 * * * * FILTER=backup /ruta/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

### Sin `FILTER`

Si no se define la variable `FILTER` o está vacía:

```
FILTER=
```

👉 El script procesará **todos los dominios** del archivo `dominios.txt`, sin filtrar.



---

### Uso combinado de FILTER desde `.env` y `cron`

El valor de `FILTER` en el archivo `.env` se puede sobrescribir directamente desde la línea de comandos o desde un trabajo programado con `cron`.

Esto permite un control más preciso para ejecutar diferentes grupos de dominios sin necesidad de duplicar scripts o modificar el archivo `.env`.

### Prioridad de configuración

| Valor en `.env` | Valor en cron/comando       | Dominio procesado        |
|------------------|-----------------------------|---------------------------|
| (vacío)          | `FILTER=main`               | Solo dominios con etiqueta `main` |
| `main`           | `FILTER=backup`             | Solo dominios con etiqueta `backup` |
| `main`           | (no sobrescrito)            | Solo dominios con etiqueta `main` |
| (vacío)          | (no sobrescrito)            | Todos los dominios se procesan     |

### Recomendación

Para mayor flexibilidad, se recomienda dejar `FILTER=` vacío en el archivo `.env` y usar filtros desde los cron jobs específicos:

```cron
# Ejecutar solo dominios principales cada 5 minutos
*/5 * * * * FILTER=main /ruta/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1

# Ejecutar solo dominios de respaldo cada hora
0 * * * * FILTER=backup /ruta/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

Esto evita tener que cambiar manualmente el archivo `.env` para cada entorno o tipo de dominio.


### Automatización con cron

```bash
*/5 * * * * /ruta/absoluta/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---


## 🇬🇧 ENGLISH

Bash script to update DNS records (A, AAAA, CNAME) in Cloudflare using your current public IP. Ideal for servers with dynamic IPs like Proxmox, home setups, or non-static environments.

This script detects the public IP, automatically matches the correct Cloudflare zone, and updates (or creates) the necessary records. It also preserves proxy status, allows custom TTL, tags, logging, and optional Discord or Telegram notifications.

---

### Features

- Supports `A`, `AAAA`, `CNAME` record types
- Custom TTL per domain
- Filtering by tag (`main`, `backup`, etc.)
- Optional logging to file (`LOGFILE`)
- Optional notifications to Discord and Telegram
- Multilingual output (`LANG=es` or `LANG=en`)
- Dependency check (`jq`, `curl`)
- Automatic public IP detection (IPv4/IPv6)
- Creates records if they don't exist
- Respects proxy setting (`true/false`)

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
nano .env  # Add your token and configuration
```

### Example `.env`:

```env
CF_API_TOKEN=your_token_here
LANG=en
LOGFILE=/var/log/flare-up.log
FILTER=
DISCORD_WEBHOOK=
TELEGRAM_TOKEN=
TELEGRAM_CHAT_ID=
```

---

### Format of dominios.txt

Each line represents a DNS record to be processed. The general format is:

```
type sub.domain.com proxy ttl tag
```

### Fields:

- `type` (optional): Can be `A`, `AAAA`, or `CNAME`. Defaults to `A` if omitted.
- `sub.domain.com` (required): Full subdomain to update.
- `proxy` (optional): `true` to enable Cloudflare proxy, `false` to disable it. Defaults to `false`.
- `ttl` (optional): Time-to-live of the record in seconds (e.g. `120`, `300`, `3600`). Defaults to `300` if not specified.
- `tag` (optional): Used to classify records for filtering. If not specified, the record has no tag.

### Valid examples:

```
A vpn.example.com true 120 main
AAAA ipv6.example.com false 300 backup
CNAME www.example.com false
file.example.net
```

---

### Run the script

```bash
chmod +x flare-up.sh
./flare-up.sh
```

---

### Tag-based Filtering (`FILTER`)

The script allows assigning **tags** to domains in the `dominios.txt` file. These tags help group domains by type or function (e.g. `main`, `backup`, `monitoring`, etc.).

### How it works

In `dominios.txt`, each line may include a **tag** at the end:

```
A vpn.yourserver.com true 120 main
AAAA ipv6.yourserver.com false 300 backup
CNAME app.yourserver.com false - monitoring
```

Then, in the `.env` file, you can set:

```
FILTER=main
```

This means only domains with the tag `main` will be processed.

### Why use it

- Run specific updates from different cron jobs
- Separate record groups by role or priority
- Test without touching production (`FILTER=dev`)
- Avoid processing all domains every time

### Practical example with cron

```
# Update only main domains every 5 minutes
*/5 * * * * FILTER=main /path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1

# Update only backup domains every hour
0 * * * * FILTER=backup /path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

### No FILTER

If the `FILTER` variable is not defined or left empty:

```
FILTER=
```

The script will process **all domains** in the `dominios.txt` file.

---

### Combined use of FILTER from `.env` and `cron`

The `FILTER` value from `.env` can be overridden directly from the command line or a cron job.

This gives more control to run different domain groups without modifying the `.env` or duplicating the script.

### Configuration priority

| Value in `.env` | Value in cron/command      | Domains processed            |
|------------------|----------------------------|-------------------------------|
| (empty)          | `FILTER=main`              | Only domains tagged `main`   |
| `main`           | `FILTER=backup`            | Only domains tagged `backup` |
| `main`           | (not overridden)           | Only domains tagged `main`   |
| (empty)          | (not overridden)           | All domains processed         |

### Recommendation

For better flexibility, it's recommended to leave `FILTER=` empty in `.env` and use filters via specific cron jobs:

```cron
# Update only main domains every 5 minutes
*/5 * * * * FILTER=main /path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1

# Update only backup domains every hour
0 * * * * FILTER=backup /path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

---

### Automate with cron

```bash
*/5 * * * * /absolute/path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```


Bash script to update Cloudflare DNS records (`A`, `AAAA`, `CNAME`) with your current public IP. Ideal for Proxmox, home servers, or any dynamic IP environment.

The script detects your IP, matches it to the correct Cloudflare zone, and updates (or creates) the necessary DNS records. Also supports TTL, tags, logging, and optional Discord/Telegram notifications.

---

### Features

- Supports `A`, `AAAA`, `CNAME` DNS records
- Custom TTL per domain
- Filter by tag (`main`, `backup`, etc.)
- Optional log file (`LOGFILE`)
- Optional notifications to Discord or Telegram
- Multilingual output (`LANG=es` or `LANG=en`)
- Dependency check (`curl`, `jq`)
- Public IP detection (IPv4/IPv6)
- Auto-creates records if missing
- Respects proxy setting (`true/false`)

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
nano .env  # Add your token and config
```

### Example `.env` file:

```env
CF_API_TOKEN=your_token_here
LANG=en
LOGFILE=/var/log/flare-up.log
FILTER=main
DISCORD_WEBHOOK=
TELEGRAM_TOKEN=
TELEGRAM_CHAT_ID=
```

---


---

### Format of dominios.txt file

Each line represents a DNS record to be managed. The general format is:

```
type sub.domain.com proxy ttl tag
```

### Fields:

- `type` (optional): Can be `A`, `AAAA`, or `CNAME`. If omitted, defaults to `A`.
- `sub.domain.com` (required): The full subdomain to update.
- `proxy` (optional): Use `true` to enable Cloudflare proxy, `false` to disable. Defaults to `false` if omitted.
- `ttl` (optional): Record time-to-live in seconds (e.g. `120`, `300`, `3600`). Defaults to `300` if not specified.
- `tag` (optional): Classify records for filtering. If omitted, the record will have no tag.

### Valid examples:

```
A vpn.example.com true 120 main
AAAA ipv6.example.com false 300 backup
CNAME www.example.com false
file.example.net
```

---


Each line defines a domain to manage. Full format:

```
type sub.domain.com proxy ttl tag
```

Fields:

- `type` (optional): A, AAAA, CNAME. Defaults to `A` if omitted.
- `proxy`: true or false
- `ttl`: time-to-live for the DNS record
- `tag`: optional label for filtering (e.g., main, backup)

### Valid examples:

```
A vpn.mysite.com true 120 main
AAAA ipv6.mysite.com false 300 backup
CNAME app.mysite.com false
noproxy.otherdomain.org
```

---

### Run the script

```bash
chmod +x flare-up.sh
./flare-up.sh
```

---


---

### Tag-based Filtering (`FILTER`)

The script allows you to assign **tags** to each domain in `dominios.txt`. These tags help organize domains by purpose (e.g., `main`, `backup`, `monitoring`, etc.).

### How it works

In the `dominios.txt` file, each line can optionally include a **tag** at the end:

```
A vpn.yourserver.com true 120 main
AAAA ipv6.yourserver.com false 300 backup
CNAME app.yourserver.com false - monitoring
```

Then, in your `.env`:

```
FILTER=main
```

Only domains tagged `main` will be updated, and the rest will be skipped.

### Use cases

- Separate `cron` jobs for different groups of domains
- Group records by function or environment
- Run tests without touching production (`FILTER=dev`)
- Avoid updating all records every time

### Cron example

```
# Update only main domains every 5 minutes
*/5 * * * * FILTER=main /path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1

# Update backup records every hour
0 * * * * FILTER=backup /path/to/flare-up/flare-up.sh >> /var/log/flare-up.log 2>&1
```

### No `FILTER`

If `FILTER` is not set or left empty:

```
FILTER=
```

👉 The script will update **all domains** in `dominios.txt`.


### Automate with cron

```bash
*/5 * * * * /absolute/path/to/flare-up.sh >> /var/log/flare-up.log 2>&1
```

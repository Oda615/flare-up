#!/bin/bash

# flare-up: Cloudflare DDNS Script (Bash)
# Actualiza registros A automáticamente usando la IP pública actual.
# Automatically updates A records in Cloudflare with your current public IP.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

DOMAINS_FILE="$SCRIPT_DIR/dominios.txt"
TTL=300

# Validación de dependencias / Dependency check
for bin in jq curl; do
    if ! command -v $bin &>/dev/null; then
        echo "❌ Faltante: $bin. Instalalo con apt o yum. / Missing: $bin"
        exit 1
    fi
done

# Verifica que el token sea válido / Verify token
VERIFY=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify)
if ! echo "$VERIFY" | grep -q '"success":true'; then
    echo "❌ Token inválido. Revisá tu .env / Invalid token"
    exit 1
fi

# Obtener IP pública actual / Get current public IP
CURRENT_IP=$(curl -s https://api.ipify.org)
[[ -z "$CURRENT_IP" ]] && { echo "❌ No se pudo obtener la IP pública / Failed to get public IP"; exit 1; }

# Función para obtener Zone ID / Get zone ID
get_zone_id() {
    local domain=$1
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" | jq -r '.result[0].id'
}

[[ ! -f "$DOMAINS_FILE" ]] && { echo "❌ No se encontró dominios.txt / File not found"; exit 1; }

# Leer cada línea de dominios.txt / Read domain list
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    FQDN=$(echo "$line" | awk '{print $1}')
    PROXY_FLAG=$(echo "$line" | awk '{print $2}')
    [[ -z "$PROXY_FLAG" ]] && PROXY_FLAG="false"

    BASE_DOMAIN=$(echo "$FQDN" | awk -F. '{print $(NF-1)"."$NF}')
    ZONE_ID=$(get_zone_id "$BASE_DOMAIN")

    [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]] && { echo "⚠️ [$FQDN] Zona no encontrada / Zone not found"; continue; }

    RECORD_DATA=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$FQDN&type=A" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json")

    RECORD_ID=$(echo "$RECORD_DATA" | jq -r '.result[0].id')
    RECORD_IP=$(echo "$RECORD_DATA" | jq -r '.result[0].content')

    if [[ "$RECORD_ID" == "null" || -z "$RECORD_ID" ]]; then
        echo "➕ [$(date '+%F %T')] $FQDN no existe. Creando... / Creating new record"

        CREATE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$FQDN\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXY_FLAG}")

        if echo "$CREATE" | grep -q '"success":true'; then
            echo "✔️ [$FQDN] creado correctamente (proxy: $PROXY_FLAG)"
        else
            echo "❌ [$FQDN] Error al crear el registro / Error creating"
        fi
        continue
    fi

    PROXIED=$(echo "$RECORD_DATA" | jq -r '.result[0].proxied')

    if [[ "$RECORD_IP" != "$CURRENT_IP" ]]; then
        echo "🔄 [$(date '+%F %T')] Actualizando $FQDN de $RECORD_IP a $CURRENT_IP"

        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$FQDN\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXIED}" | jq .
    else
        echo "✅ [$(date '+%F %T')] $FQDN ya está actualizado / Already up to date"
    fi

done < "$DOMAINS_FILE"

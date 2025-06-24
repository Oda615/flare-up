#!/bin/bash

# flare-up: Cloudflare DDNS Script (Bash)
# Actualiza registros A automáticamente usando la IP pública actual.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

DOMAINS_FILE="$SCRIPT_DIR/dominios.txt"
TTL=300

# Validación de dependencias
for bin in jq curl; do
    if ! command -v $bin &>/dev/null; then
        echo "[ERROR] Requisito faltante: $bin"
        exit 1
    fi
done

# Verificar token
VERIFY=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify)
if ! echo "$VERIFY" | grep -q '"success":true'; then
    echo "[ERROR] Token inválido. Verifica el archivo .env"
    exit 1
fi

# Obtener IP pública
CURRENT_IP=$(curl -s https://api.ipify.org)
[[ -z "$CURRENT_IP" ]] && { echo "[ERROR] No se pudo obtener la IP pública"; exit 1; }

# Obtener Zone ID
get_zone_id() {
    local domain=$1
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" | jq -r '.result[0].id'
}

[[ ! -f "$DOMAINS_FILE" ]] && { echo "[ERROR] No se encontró dominios.txt"; exit 1; }

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    FQDN=$(echo "$line" | awk '{print $1}')
    PROXY_FLAG=$(echo "$line" | awk '{print $2}')
    [[ -z "$PROXY_FLAG" ]] && PROXY_FLAG="false"

    BASE_DOMAIN=$(echo "$FQDN" | awk -F. '{print $(NF-1)"."$NF}')
    ZONE_ID=$(get_zone_id "$BASE_DOMAIN")

    [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]] && { echo "[INFO] $(date '+%F %T') Zona no encontrada para $FQDN"; continue; }

    RECORD_DATA=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$FQDN&type=A" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json")

    RECORD_ID=$(echo "$RECORD_DATA" | jq -r '.result[0].id')
    RECORD_IP=$(echo "$RECORD_DATA" | jq -r '.result[0].content')

    if [[ "$RECORD_ID" == "null" || -z "$RECORD_ID" ]]; then
        echo "[INFO] $(date '+%F %T') Creando nuevo registro A para $FQDN"

        CREATE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$FQDN\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXY_FLAG}")

        if echo "$CREATE" | grep -q '"success":true'; then
            echo "[OK] $FQDN creado correctamente (proxy: $PROXY_FLAG)"
        else
            echo "[ERROR] Fallo al crear el registro para $FQDN"
        fi
        continue
    fi

    PROXIED=$(echo "$RECORD_DATA" | jq -r '.result[0].proxied')

    if [[ "$RECORD_IP" != "$CURRENT_IP" ]]; then
        echo "[INFO] $(date '+%F %T') Actualizando $FQDN de $RECORD_IP a $CURRENT_IP"

        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$FQDN\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXIED}" | jq .
    else
        echo "[INFO] $(date '+%F %T') $FQDN ya está actualizado"
    fi

done < "$DOMAINS_FILE"

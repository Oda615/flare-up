#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

DOMAINS_FILE="$SCRIPT_DIR/dominios.txt"
DEFAULT_TTL=300
LANG="${LANG:-es}"
FILTER="${FILTER:-}"

log() {
  local type="$1"
  local msg_es="$2"
  local msg_en="$3"
  local timestamp
  timestamp="$(date '+%F %T')"
  local output="[$timestamp] [$type] "
  output+=$([[ "$LANG" == "es" ]] && echo "$msg_es" || echo "$msg_en")
  echo "$output"
  [[ -n "$LOGFILE" ]] && echo "$output" >> "$LOGFILE"
}

notify() {
  local message="$1"
  [[ -n "$DISCORD_WEBHOOK" ]] && curl -s -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$DISCORD_WEBHOOK" >/dev/null
  [[ -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]] && curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"       -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message" >/dev/null
}

get_zone_id() {
    local domain=$1
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" | jq -r '.result[0].id'
}

for bin in jq curl; do
    if ! command -v $bin &>/dev/null; then
        log ERROR "Requisito faltante: $bin" "Missing requirement: $bin"
        exit 1
    fi
done

VERIFY=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify)
if ! echo "$VERIFY" | grep -q '"success":true'; then
    log ERROR "Token inválido. Verifica el archivo .env" "Invalid token. Check your .env file"
    exit 1
fi

IPV4=$(curl -s https://api.ipify.org)
[[ -z "$IPV4" ]] && { log ERROR "No se pudo obtener la IP pública" "Could not retrieve public IP"; exit 1; }

[[ ! -f "$DOMAINS_FILE" ]] && { log ERROR "No se encontró dominios.txt" "File dominios.txt not found"; exit 1; }

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    TYPE=$(echo "$line" | awk '{print $1}')
    [[ "$TYPE" =~ ^(A|AAAA|CNAME)$ ]] || { TYPE="A"; FIELD_OFFSET=0; }
    [[ "$TYPE" != "A" && "$TYPE" != "AAAA" && "$TYPE" != "CNAME" ]] && continue
    [[ -n "$FIELD_OFFSET" ]] || FIELD_OFFSET=1

    FQDN=$(echo "$line" | awk -v o="$FIELD_OFFSET" '{print $(1+o)}')
    PROXY_FLAG=$(echo "$line" | awk -v o="$FIELD_OFFSET" '{print $(2+o)}')
    TTL_OVERRIDE=$(echo "$line" | awk -v o="$FIELD_OFFSET" '{print $(3+o)}')
    TAG=$(echo "$line" | awk -v o="$FIELD_OFFSET" '{print $(4+o)}')

    [[ -z "$PROXY_FLAG" ]] && PROXY_FLAG="false"
    TTL="${TTL_OVERRIDE:-$DEFAULT_TTL}"
    [[ -n "$FILTER" && "$TAG" != "$FILTER" ]] && continue

    BASE_DOMAIN=$(echo "$FQDN" | awk -F. '{print $(NF-1)"."$NF}')
    ZONE_ID=$(get_zone_id "$BASE_DOMAIN")

    [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]] && { log INFO "Zona no encontrada para $FQDN" "Zone not found for $FQDN"; continue; }

    RECORD_DATA=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$FQDN&type=$TYPE" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json")

    RECORD_ID=$(echo "$RECORD_DATA" | jq -r '.result[0].id')
    RECORD_IP=$(echo "$RECORD_DATA" | jq -r '.result[0].content')

    CURRENT_IP=$([[ "$TYPE" == "AAAA" ]] && curl -s https://api64.ipify.org || echo "$IPV4")

    if [[ "$RECORD_ID" == "null" || -z "$RECORD_ID" ]]; then
        log INFO "Creando $TYPE $FQDN" "Creating $TYPE $FQDN"
        CREATE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"$TYPE\",\"name\":\"$FQDN\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXY_FLAG}")

        if echo "$CREATE" | grep -q '"success":true'; then
            log OK "$FQDN creado correctamente" "$FQDN created successfully"
            notify "flare-up: $FQDN $TYPE creado con IP $CURRENT_IP"
        else
            log ERROR "Error creando $FQDN" "Failed to create $FQDN"
        fi
        continue
    fi

    if [[ "$RECORD_IP" != "$CURRENT_IP" ]]; then
        log INFO "Actualizando $FQDN de $RECORD_IP a $CURRENT_IP" "Updating $FQDN from $RECORD_IP to $CURRENT_IP"
        UPDATE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"$TYPE\",\"name\":\"$FQDN\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXY_FLAG}")

        if echo "$UPDATE" | grep -q '"success":true'; then
            log OK "$FQDN actualizado a $CURRENT_IP" "$FQDN updated to $CURRENT_IP"
            notify "flare-up: $FQDN $TYPE actualizado a $CURRENT_IP"
        else
            log ERROR "Error actualizando $FQDN" "Failed to update $FQDN"
        fi
    else
        log INFO "$FQDN ya actualizado" "$FQDN is already up to date"
    fi

done < "$DOMAINS_FILE"

#!/usr/bin/env bash
#
# directus.sh — thin authenticated client for the BNI Brasil Directus CRM.
#
# Usage:
#   directus.sh <METHOD> <PATH> [JSON_BODY]
#
# Examples:
#   directus.sh GET  "server/info"
#   directus.sh GET  "collections"
#   directus.sh GET  "items/leads?limit=5&fields=id,status"
#   directus.sh GET  "items/leads?aggregate[count]=*"
#   directus.sh POST "items/leads" '{"lead_primeiro_nome":"Ana","status":"novo"}'
#   directus.sh PATCH  "items/leads/<id>" '{"status":"qualificado"}'
#   directus.sh DELETE "items/leads/<id>"
#
# Configuration (env vars override the defaults):
#   BNI_DIRECTUS_URL    Base URL   (default: https://crm.bnibrasil.com.br)
#   BNI_DIRECTUS_TOKEN  Static token
#
# Notes:
#   * Query-string brackets used by Directus (filter[...], aggregate[...]) are
#     URL-encoded automatically so you can pass them literally.
#   * Response JSON is pretty-printed when python3 is available.
#   * Exits non-zero on HTTP >= 400.

set -euo pipefail

BASE_URL="${BNI_DIRECTUS_URL:-https://crm.bnibrasil.com.br}"
TOKEN="${BNI_DIRECTUS_TOKEN:-frKE_LRqF9YeAw3_uvtHiu6Y6dEffAN1}"

if [[ $# -lt 2 ]]; then
  echo "Usage: directus.sh <METHOD> <PATH> [JSON_BODY]" >&2
  echo "Example: directus.sh GET \"items/leads?limit=5\"" >&2
  exit 64
fi

METHOD="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
RAW_PATH="$2"
BODY="${3:-}"

# Strip a leading slash so both "items/x" and "/items/x" work.
RAW_PATH="${RAW_PATH#/}"

# Split path and query so we can encode only the query's brackets/spaces.
if [[ "$RAW_PATH" == *\?* ]]; then
  PATH_PART="${RAW_PATH%%\?*}"
  QUERY_PART="${RAW_PATH#*\?}"
  QUERY_PART="${QUERY_PART//\[/%5B}"
  QUERY_PART="${QUERY_PART//\]/%5D}"
  QUERY_PART="${QUERY_PART// /%20}"
  URL="${BASE_URL%/}/${PATH_PART}?${QUERY_PART}"
else
  URL="${BASE_URL%/}/${RAW_PATH}"
fi

curl_args=(
  -sS
  --max-time 60
  -w $'\n%{http_code}'
  -X "$METHOD"
  -H "Authorization: Bearer ${TOKEN}"
  -H "Accept: application/json"
)

if [[ -n "$BODY" ]]; then
  curl_args+=(-H "Content-Type: application/json" --data "$BODY")
fi

RESPONSE="$(curl "${curl_args[@]}" "$URL")"
HTTP_CODE="${RESPONSE##*$'\n'}"
PAYLOAD="${RESPONSE%$'\n'*}"

if command -v python3 >/dev/null 2>&1 && [[ -n "$PAYLOAD" ]]; then
  printf '%s' "$PAYLOAD" | python3 -m json.tool 2>/dev/null || printf '%s\n' "$PAYLOAD"
else
  printf '%s\n' "$PAYLOAD"
fi

if [[ "$HTTP_CODE" =~ ^[0-9]+$ ]] && (( HTTP_CODE >= 400 )); then
  echo "HTTP ${HTTP_CODE}" >&2
  exit 1
fi

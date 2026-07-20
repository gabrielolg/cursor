#!/usr/bin/env bash
#
# n8n.sh — authenticated client for the BNI Brasil n8n Public REST API (/api/v1).
#
# Usage:
#   n8n.sh <METHOD> <PATH> [JSON_BODY]
#
# Examples:
#   n8n.sh GET  "workflows?limit=20"
#   n8n.sh GET  "workflows/<id>"
#   n8n.sh GET  "executions?status=error&limit=10&includeData=false"
#   n8n.sh POST "workflows/<id>/activate"
#   n8n.sh POST "workflows" '{"name":"My WF","nodes":[],"connections":{},"settings":{}}'
#   n8n.sh PUT  "workflows/<id>" '{...}'
#   n8n.sh DELETE "executions/<id>"
#
# Configuration — provide via environment (never hardcode secrets):
#   BNI_N8N_URL      Base URL   (default: https://n8n.bnibrasil.com.br)
#   BNI_N8N_API_KEY  n8n public API key (sent as X-N8N-API-KEY) — REQUIRED
#
# You can export these in your shell, or drop them in an untracked
# ".cursor/skills/bni-n8n/.env" file (gitignored) which this script auto-loads.
#
# Notes:
#   * The path is relative to "<base>/api/v1/". A leading slash is tolerated.
#   * Auth uses the X-N8N-API-KEY header (the Public API scheme), not Bearer.
#   * Response JSON is pretty-printed when python3 is available.
#   * Exits non-zero on HTTP >= 400.

set -euo pipefail

# Auto-load local, untracked secrets if present (never committed).
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for envfile in "$SKILL_DIR/.env" "$SKILL_DIR/secrets.env"; do
  [[ -f "$envfile" ]] && { set -a; . "$envfile"; set +a; }
done

BASE_URL="${BNI_N8N_URL:-https://n8n.bnibrasil.com.br}"
API_KEY="${BNI_N8N_API_KEY:?BNI_N8N_API_KEY is not set. Export it or add it to .cursor/skills/bni-n8n/.env (see SKILL.md).}"

if [[ $# -lt 2 ]]; then
  echo "Usage: n8n.sh <METHOD> <PATH> [JSON_BODY]" >&2
  echo "Example: n8n.sh GET \"workflows?limit=20\"" >&2
  exit 64
fi

METHOD="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
RAW_PATH="${2#/}"
RAW_PATH="${RAW_PATH#api/v1/}"   # allow passing with or without the api/v1 prefix
BODY="${3:-}"

URL="${BASE_URL%/}/api/v1/${RAW_PATH}"

curl_args=(
  -sS
  --max-time 60
  -w $'\n%{http_code}'
  -X "$METHOD"
  -H "X-N8N-API-KEY: ${API_KEY}"
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

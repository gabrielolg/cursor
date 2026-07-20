#!/usr/bin/env bash
#
# mcp-probe.sh — quick connectivity/auth check for the n8n native MCP server
# (Streamable HTTP transport at /mcp-server/http). Useful to verify an MCP
# Access Token before wiring it into .cursor/mcp.json.
#
# Usage:
#   mcp-probe.sh                # sends an "initialize" JSON-RPC request
#   mcp-probe.sh tools/list     # sends the given method (no params)
#
# Configuration:
#   BNI_N8N_URL        Base URL (default: https://n8n.bnibrasil.com.br)
#   BNI_N8N_MCP_TOKEN  MCP Access Token (Bearer). REQUIRED for a 200 response.
#
# Note: a public-API key will return HTTP 401 (audience mismatch). You must use
# an MCP Access Token from n8n Settings -> Instance-level MCP -> Access Token.

set -euo pipefail

BASE_URL="${BNI_N8N_URL:-https://n8n.bnibrasil.com.br}"
TOKEN="${BNI_N8N_MCP_TOKEN:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwNzFiOGU0Mi04ZGI1LTQ2ZjgtYjRkYi00OWFiNWU0YjJkZjUiLCJpc3MiOiJuOG4iLCJhdWQiOiJtY3Atc2VydmVyLWFwaSIsImp0aSI6IjZhM2ZjYzNiLWNmMDAtNDRiNy04MDFiLWZjMWRjODdmMDNmNyIsImlhdCI6MTc4NDU2MDEzNH0.9sHF1XQpYUdU2RePAvUwCo3QUqKvQqPDuYuoCv1XK0o}"
METHOD="${1:-initialize}"

if [[ -z "$TOKEN" ]]; then
  echo "warning: BNI_N8N_MCP_TOKEN is not set; expect HTTP 401." >&2
fi

if [[ "$METHOD" == "initialize" ]]; then
  PARAMS='{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"bni-n8n-probe","version":"1.0"}}'
else
  PARAMS='{}'
fi

REQ="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"${METHOD}\",\"params\":${PARAMS}}"

curl -sS --max-time 30 -D - \
  -X POST "${BASE_URL%/}/mcp-server/http" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  --data "$REQ"
echo

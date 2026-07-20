---
name: bni-n8n
description: Access the BNI Brasil n8n automation platform (https://n8n.bnibrasil.com.br) — list/inspect/run workflows, read executions, tags, variables, projects and users. Use this skill whenever the user asks about BNI Brasil n8n, its workflows, automations, executions/runs, or the n8n MCP server.
metadata:
  vendor: BNI Brasil
  product: n8n
  mcp_endpoint: https://n8n.bnibrasil.com.br/mcp-server/http
---

# BNI Brasil — n8n automation platform

This skill connects to the **BNI Brasil** n8n instance at `https://n8n.bnibrasil.com.br`.
There are two ways to talk to it, and this skill supports both:

1. **n8n MCP server** (native, at `/mcp-server/http`) — preferred for tool-style access,
   requires a dedicated **MCP Access Token**.
2. **n8n Public REST API** (`/api/v1/...`) — works today with the provided API key; use the
   `scripts/n8n.sh` helper.

## When to use

Use this skill when the user wants to:

- List, search, read, activate/deactivate, create, update, or run n8n workflows.
- Inspect executions/runs (status, errors, data) of BNI Brasil automations.
- Read tags, variables, projects, users, or credential schemas.
- Configure or troubleshoot the n8n MCP server connection.

## Configuration

| Variable          | Default                                    | Description                        |
| ----------------- | ------------------------------------------ | ---------------------------------- |
| `BNI_N8N_URL`     | `https://n8n.bnibrasil.com.br`             | Base URL of the n8n instance       |
| `BNI_N8N_API_KEY` | (n8n public API key, see script)           | Key for the Public REST API        |
| `BNI_N8N_MCP_TOKEN` | (MCP Access Token — see important note)  | Token for the MCP server endpoint  |

> **Security note:** These are credentials. Prefer env vars / Cursor secrets over the
> committed defaults, and rotate them in n8n (Settings) if exposed.

### ⚠️ Important: MCP token vs. Public API key

The token supplied for this instance is an **n8n Public API key** (`aud: public-api`). It
authenticates the **Public REST API** perfectly, but the native **MCP server returns 401
(audience mismatch)** for public-API keys — this is by design in n8n.

To use the MCP endpoint you need a dedicated **MCP Access Token**:

1. In n8n: **Settings → Instance-level MCP → Enable MCP access** (owner/admin only).
2. Open **Connection details → Access Token** and copy the generated MCP Access Token.
3. Put it in `BNI_N8N_MCP_TOKEN` and in `.cursor/mcp.json` (see `references/api.md`).

Until then, use the **Public REST API** path below — it is fully functional.

## Using the Public REST API (works now)

Prefer the helper script; it handles auth, base URL, and JSON pretty-printing:

```bash
scripts/n8n.sh GET  "workflows?limit=20"
scripts/n8n.sh GET  "workflows?active=true&limit=50&excludePinnedData=true"
scripts/n8n.sh GET  "workflows/<id>"
scripts/n8n.sh GET  "executions?status=error&limit=20&includeData=false"
scripts/n8n.sh GET  "executions/<id>?includeData=true"
scripts/n8n.sh POST "workflows/<id>/activate"
scripts/n8n.sh POST "workflows/<id>/deactivate"
scripts/n8n.sh GET  "tags?limit=100"
scripts/n8n.sh GET  "variables"
scripts/n8n.sh GET  "projects"
```

Raw curl equivalent (auth header is `X-N8N-API-KEY`, **not** Bearer):

```bash
curl -s -H "X-N8N-API-KEY: $BNI_N8N_API_KEY" \
  "$BNI_N8N_URL/api/v1/workflows?limit=20"
```

### REST cheat sheet

- `GET /workflows` — params: `active`, `tags`, `name`, `projectId`, `limit` (max 250),
  `cursor` (pagination), `excludePinnedData`. `GET /workflows/{id}` for one.
- `POST /workflows` — create. `PUT /workflows/{id}` — update. `DELETE /workflows/{id}`.
  `POST /workflows/{id}/activate` · `POST /workflows/{id}/deactivate`.
- `GET /executions` — params: `status` (`success|error|waiting`), `workflowId`,
  `includeData`, `limit`, `cursor`. `GET /executions/{id}` · `DELETE /executions/{id}`.
- `GET /tags`, `GET /variables`, `GET /projects`, `GET /users`.
- `GET /credentials/schema/{type}` — schema for a credential type (e.g. `n8nApi`).
- **Pagination is cursor-based**: responses include `nextCursor`; pass it back as `cursor`.
  Iterate until `nextCursor` is null.

## Using the MCP server (once you have an MCP Access Token)

Register it in `.cursor/mcp.json` so Cursor exposes the `bni-n8n` MCP tools:

```json
{
  "mcpServers": {
    "bni-n8n": {
      "url": "https://n8n.bnibrasil.com.br/mcp-server/http",
      "headers": { "Authorization": "Bearer <YOUR_N8N_MCP_TOKEN>" }
    }
  }
}
```

A starter `.cursor/mcp.json` is included at the repo root — replace the token with a real
MCP Access Token. When the MCP tools are available, prefer them over raw REST for tasks the
MCP server exposes. To probe/debug the endpoint directly over Streamable HTTP, use
`scripts/mcp-probe.sh` (see `references/api.md`).

## Operational notes

- **Reads are safe; be careful with writes.** Confirm intent before creating/updating/
  deleting workflows, activating/deactivating, or deleting executions.
- **Don't dump huge payloads.** Use `excludePinnedData=true` and `includeData=false` when
  listing, and only fetch full node/execution data for a specific id when needed.
- Instance language is Portuguese; workflow names/tags are in PT (e.g. `Secretária`,
  `DIRECTUS`, `CHATWOOT`, `SDR`).

See `references/api.md` for the full endpoint list observed on this instance and MCP setup
details.

---
name: liga-digital-n8n
description: Access the Liga Digital n8n automation platform (https://n8n-editor.iali.io) — list/inspect/run workflows, read executions, tags and users. Use this skill whenever the user asks about Liga Digital n8n, IALI, its workflows, automations, executions/runs, or the n8n MCP server.
metadata:
  vendor: Liga Digital
  product: n8n
  mcp_endpoint: https://n8n-editor.iali.io/mcp-server/http
---

# Liga Digital — n8n automation platform

This skill connects to the **Liga Digital** n8n instance at `https://n8n-editor.iali.io`
(the "IALI" project). There are two ways to talk to it, and this skill supports both (both
are configured and verified working):

1. **n8n MCP server** (native, at `/mcp-server/http`) — preferred for tool-style access to
   search, inspect and run workflows. Configured in `.cursor/mcp.json` with the instance MCP
   Access Token.
2. **n8n Public REST API** (`/api/v1/...`) — direct read/write via the `scripts/n8n.sh`
   helper; handy for quick queries, scripting, and anything the MCP server doesn't expose
   (creating/updating workflows, activating/deactivating, tags, users, etc.).

## When to use

Use this skill when the user wants to:

- List, search, read, activate/deactivate, create, update, or run n8n workflows on the
  Liga Digital / IALI instance.
- Inspect executions/runs (status, errors, data) of Liga Digital automations.
- Read tags, users, or credential schemas.
- Configure or troubleshoot the n8n MCP server connection.

## Configuration

Credentials are **never hardcoded** — they are read from the environment:

| Variable                     | Required | Description                                          |
| ----------------------------- | -------- | ----------------------------------------------------- |
| `LIGA_DIGITAL_N8N_URL`       | no       | Base URL (default `https://n8n-editor.iali.io`)       |
| `LIGA_DIGITAL_N8N_API_KEY`   | for REST | Public REST API key (sent as `X-N8N-API-KEY`)         |
| `LIGA_DIGITAL_N8N_MCP_TOKEN` | for MCP  | MCP Access Token (sent as `Authorization: Bearer`)    |

**How to provide them (pick one):**

- Export in your shell profile: `export LIGA_DIGITAL_N8N_API_KEY=... LIGA_DIGITAL_N8N_MCP_TOKEN=...`
- Copy `.env.example` to `.env` in this skill folder and fill it in — the scripts
  auto-load it and it is **gitignored** (never committed).
- For Cursor **Cloud Agents**, set them as **Cursor secrets** (Dashboard → Secrets) so
  they are injected as environment variables.

`.cursor/mcp.json` references the MCP token via `${env:LIGA_DIGITAL_N8N_MCP_TOKEN}`, so it
must be present in the environment Cursor is launched from.

> **Security note:** These are credentials — never commit them. Rotate them in n8n
> (Settings) if they are ever exposed.

### Two distinct tokens — don't mix them up

n8n uses **different tokens per audience**, and they are not interchangeable:

- **Public REST API** → `X-N8N-API-KEY` header, a Public API key (`aud: public-api`).
- **MCP server** → `Authorization: Bearer` header, an **MCP Access Token**
  (`aud: mcp-server-api`), from **Settings → Instance-level MCP → Connection details →
  Access Token**. A public-API key is rejected here with `401` (audience mismatch).

## Using the Public REST API

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
scripts/n8n.sh GET  "users"
```

Raw curl equivalent (auth header is `X-N8N-API-KEY`, **not** Bearer):

```bash
curl -s -H "X-N8N-API-KEY: $LIGA_DIGITAL_N8N_API_KEY" \
  "$LIGA_DIGITAL_N8N_URL/api/v1/workflows?limit=20"
```

### REST cheat sheet

- `GET /workflows` — params: `active`, `tags`, `name`, `projectId`, `limit` (max 250),
  `cursor` (pagination), `excludePinnedData`. `GET /workflows/{id}` for one.
- `POST /workflows` — create. `PUT /workflows/{id}` — update. `DELETE /workflows/{id}`.
  `POST /workflows/{id}/activate` · `POST /workflows/{id}/deactivate`.
- `GET /executions` — params: `status` (`success|error|waiting`), `workflowId`,
  `includeData`, `limit`, `cursor`. `GET /executions/{id}` · `DELETE /executions/{id}`.
- `GET /tags`, `GET /users`.
- `GET /credentials/schema/{type}` — schema for a credential type (e.g. `n8nApi`).
- **Pagination is cursor-based**: responses include `nextCursor`; pass it back as `cursor`.
  Iterate until `nextCursor` is null.
- `GET /variables` and `GET /projects` return **HTTP 403** on this instance
  (`Your license does not allow for feat:variables` / `feat:projectRole:admin`) — this is
  a Community-edition license limit, not an auth problem. Don't retry these with a
  different key.

## Using the MCP server

The `liga-digital-n8n` MCP server is registered in `.cursor/mcp.json` at the repo root
(Streamable HTTP, Bearer MCP Access Token) — Cursor exposes its tools automatically.

Server: `n8n MCP Server` v1.0.0. This instance exposes a **small, fixed tool set** (unlike
some other n8n instances that run a fuller workflow-authoring MCP toolset):

- `search_workflows` — search workflows by name/description, returns a preview (id, name,
  active, timestamps, triggerCount, nodes) for each match.
- `get_workflow_details` — full details (nodes, connections, tags, trigger info) for one
  workflow by id.
- `execute_workflow` — execute a workflow by id, with `chat`, `form`, or `webhook`-shaped
  inputs depending on how the workflow is triggered. **Destructive/side-effecting** —
  confirm intent before calling.

There are **no MCP tools for creating/updating/activating workflows or reading
executions** on this instance — use the Public REST API (`scripts/n8n.sh`) for those.

> Before calling `execute_workflow`, always call `get_workflow_details` first to learn the
> expected trigger/input shape (chat vs. form vs. webhook) — don't guess the input schema.

To probe/debug the endpoint directly over Streamable HTTP, use `scripts/mcp-probe.sh`
(see `references/api.md`).

## Operational notes

- **Reads are safe; be careful with writes.** Confirm intent before creating/updating/
  deleting workflows, activating/deactivating, deleting executions, or executing a
  workflow via MCP.
- **Don't dump huge payloads.** Use `excludePinnedData=true` and `includeData=false` when
  listing, and only fetch full node/execution data for a specific id when needed.
- Instance language is Portuguese; workflow names/tags are in PT (e.g. `Secretária`,
  `DIRECTUS`, `CHATWOOT`, `SDR`, `IALI`, `LIGA DIGITAL`). Many workflow names are prefixed
  by project/area, e.g. `IALI - ...`, `TOOL - ...`, `DIRECTUS - ...`, `FLÓRIDA - ...`,
  `JURÍDICO - ...`.

See `references/api.md` for the full endpoint list observed on this instance and MCP setup
details.

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
There are two ways to talk to it, and this skill supports both (both are configured and
verified working):

1. **n8n MCP server** (native, at `/mcp-server/http`) — preferred for tool-style access
   (build/validate/run workflows via the n8n Workflow SDK). Configured in
   `.cursor/mcp.json` with the instance MCP Access Token.
2. **n8n Public REST API** (`/api/v1/...`) — direct read/write via the `scripts/n8n.sh`
   helper; handy for quick queries and scripting.

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
| `BNI_N8N_MCP_TOKEN` | (n8n MCP Access Token, see script/mcp.json)| Bearer token for the MCP server    |

> **Security note:** These are credentials. Prefer env vars / Cursor secrets over the
> committed defaults, and rotate them in n8n (Settings) if exposed.

### Two distinct tokens — don't mix them up

n8n uses **different tokens per audience**, and they are not interchangeable:

- **Public REST API** → `X-N8N-API-KEY` header, a Public API key (`aud: public-api`).
- **MCP server** → `Authorization: Bearer` header, an **MCP Access Token**
  (`aud: mcp-server-api`), from **Settings → Instance-level MCP → Connection details →
  Access Token**. A public-API key is rejected here with `401` (audience mismatch).

Both tokens are already configured in this skill (`scripts/` defaults and `.cursor/mcp.json`).

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

## Using the MCP server

The `bni-n8n` MCP server is registered in `.cursor/mcp.json` at the repo root (Streamable
HTTP, Bearer MCP Access Token) — Cursor exposes its tools automatically. **Prefer the MCP
tools over raw REST** for building/validating/running workflows.

Server: `n8n MCP Server` v1.1.0. Key tools include:

- Discovery/planning: `get_sdk_reference`, `get_suggested_nodes`, `search_nodes`,
  `get_node_types`.
- Workflows: `search_workflows`, `get_workflow_details`, `create_workflow_from_code`,
  `update_workflow`, `validate_workflow`, `validate_node_config`, `publish_workflow`,
  `unpublish_workflow`, `archive_workflow`.
- Runs/tests: `execute_workflow`, `get_execution`, `search_executions`,
  `prepare_test_pin_data`, `test_workflow`.
- Data/other: `list_credentials`, `search_projects`, `search_folders`,
  `search_data_tables`, `create_data_table`, `add_data_table_rows`, and more.

> When creating/updating workflows via MCP, follow the server's required order: call
> `get_sdk_reference` and `get_suggested_nodes` first, then `search_nodes` + `get_node_types`,
> then `validate_workflow` before `create_workflow_from_code`. Don't guess SDK syntax.

To probe/debug the endpoint directly over Streamable HTTP, use `scripts/mcp-probe.sh`
(see `references/api.md`).

## Operational notes

- **Reads are safe; be careful with writes.** Confirm intent before creating/updating/
  deleting workflows, activating/deactivating, or deleting executions.
- **Don't dump huge payloads.** Use `excludePinnedData=true` and `includeData=false` when
  listing, and only fetch full node/execution data for a specific id when needed.
- Instance language is Portuguese; workflow names/tags are in PT (e.g. `Secretária`,
  `DIRECTUS`, `CHATWOOT`, `SDR`).

See `references/api.md` for the full endpoint list observed on this instance and MCP setup
details.

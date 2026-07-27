# Liga Digital n8n — API & MCP reference

Instance: `https://n8n-editor.iali.io` (project "IALI")

Two interfaces are available:

- **Public REST API** — base `https://n8n-editor.iali.io/api/v1`, auth header
  `X-N8N-API-KEY: <api-key>`. **Verified working** with the provided key.
- **Native MCP server** — `https://n8n-editor.iali.io/mcp-server/http`
  (Streamable HTTP), auth `Authorization: Bearer <MCP-Access-Token>`.
  **Verified working** (`n8n MCP Server` v1.0.0) with the configured MCP Access Token.

## Public REST API — endpoints verified on this instance

| Endpoint                          | Purpose                                   | Status |
| --------------------------------- | ------------------------------------------ | ------ |
| `GET /workflows`                  | List workflows (cursor paginated)         | 200 |
| `GET /workflows/{id}`             | Get one workflow (full nodes/connections) | 200 |
| `POST /workflows`                 | Create workflow                           | (not exercised; documented n8n API) |
| `PUT /workflows/{id}`             | Update workflow                           | (not exercised; documented n8n API) |
| `DELETE /workflows/{id}`          | Delete workflow                           | (not exercised; documented n8n API) |
| `POST /workflows/{id}/activate`   | Activate                                  | (not exercised; documented n8n API) |
| `POST /workflows/{id}/deactivate` | Deactivate                                | (not exercised; documented n8n API) |
| `GET /executions`                 | List executions/runs                      | 200 |
| `GET /executions/{id}`            | Get one execution (`?includeData=true`)   | (not exercised; documented n8n API) |
| `DELETE /executions/{id}`         | Delete an execution                       | (not exercised; documented n8n API) |
| `GET /tags`                       | List tags                                 | 200 |
| `GET /variables`                  | List environment variables                | **403** — license limit (`feat:variables`) |
| `GET /projects`                   | List projects                             | **403** — license limit (`feat:projectRole:admin`) |
| `GET /users`                      | List users                                | 200 |
| `GET /credentials/schema/{type}`  | Credential type schema (e.g. `n8nApi`)    | 200 |

The `/variables` and `/projects` 403s are the n8n **Community edition license** rejecting
enterprise-only features — they are not caused by an insufficient API key/scope, and
retrying with a different token will not help.

### Workflow object fields (from `GET /workflows`)

```
updatedAt, createdAt, id, name, active, isArchived, nodes, connections,
settings, staticData, meta, pinData, versionId, activeVersionId,
triggerCount, shared, activeVersion, tags
```

### Query parameters

- `GET /workflows`: `active` (bool), `tags` (csv), `name`, `projectId`,
  `excludePinnedData` (bool), `limit` (max 250), `cursor`.
- `GET /executions`: `status` (`success|error|waiting`), `workflowId`,
  `includeData` (bool), `limit`, `cursor`.
- **Pagination is cursor-based**: use the `nextCursor` value from the response as
  the `cursor` param on the next call; stop when `nextCursor` is null.

### Instance snapshot (at verification time)

- ~240 workflows total (single `GET /workflows?limit=250` page, `nextCursor: null`).
- Single user: `contato@ligadigital.online` (Gabriel Galvao).

### Tags observed

```
ASAAS, ATENDENTE, CHATWOOT, CORREÇÃO, CRIPTO, DIRECTUS, EDUZZ, FLÓRIDA, GERAL,
IALI 6.0, IEJA, IMÓVEIS, JURÍDICO, LIGA DIGITAL, PROSPECÇÃO, SDR, SECRETÁRIA,
SISTEMA, SUPERVISORA, SUPORTE
```

### Workflow naming conventions observed

Workflow names are generally prefixed by project/area, e.g.:

```
IALI - ...          (main assistant flows, e.g. "IALI - Secretária", "IALI - Corretor Cliente")
TOOL - ...           (reusable sub-workflow "tools" called by IALI flows)
DIRECTUS - ...       (Directus CRM integration flows)
FLÓRIDA - ...        (a specific client/project flow)
JURÍDICO - ...       (legal/juridical flows)
CHATWOOT - ...       (Chatwoot integration/monitoring)
```

## MCP server

The native MCP server is configured in `.cursor/mcp.json` at the repo root and is verified
working (`n8n MCP Server` v1.0.0). It needs a dedicated **MCP Access Token** (`aud:
mcp-server-api`) — a Public API key is rejected with `401 Unauthorized` (audience
mismatch, by design).

To rotate/replace the token: n8n **Settings → Instance-level MCP → Enable MCP access**
(owner/admin) → **Connection details → Access Token**, then update `.cursor/mcp.json` and
`LIGA_DIGITAL_N8N_MCP_TOKEN`.

```json
{
  "mcpServers": {
    "liga-digital-n8n": {
      "url": "https://n8n-editor.iali.io/mcp-server/http",
      "headers": { "Authorization": "Bearer <YOUR_N8N_MCP_TOKEN>" }
    }
  }
}
```

Verify a token with the probe script:

```bash
LIGA_DIGITAL_N8N_MCP_TOKEN="<token>" scripts/mcp-probe.sh initialize   # expect HTTP 200
```

### MCP tools exposed (from `tools/list`)

This instance exposes only **three** tools (a smaller, fixed set than some other n8n
instances, which run a fuller workflow-authoring MCP toolset):

- `search_workflows(limit?, query?, projectId?)` — read-only. Returns
  `{ data: [{ id, name, description, active, createdAt, updatedAt, triggerCount, nodes }], count }`.
- `get_workflow_details(workflowId)` — read-only. Returns
  `{ workflow: {...sanitized workflow...}, triggerInfo }`.
- `execute_workflow(workflowId, inputs?)` — **destructive/side-effecting**. `inputs` is one
  of:
  - `{ type: "chat", chatInput: string }`
  - `{ type: "form", formData: object }`
  - `{ type: "webhook", webhookData: { method?, query?, body?, headers? } }`

  Returns `{ success, executionId, result?, error? }`.

There are no MCP tools here for creating/updating/validating/publishing workflows,
managing credentials/projects/folders/data tables, or listing executions — use the Public
REST API for those (see table above).

### Auth quick reference

| Interface        | Header                              | Token type        |
| ----------------- | ------------------------------------ | ------------------ |
| Public REST API  | `X-N8N-API-KEY: <key>`              | Public API key    |
| MCP server       | `Authorization: Bearer <token>`     | MCP Access Token  |

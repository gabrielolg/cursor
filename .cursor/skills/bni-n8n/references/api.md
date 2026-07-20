# BNI Brasil n8n — API & MCP reference

Instance: `https://n8n.bnibrasil.com.br`

Two interfaces are available:

- **Public REST API** — base `https://n8n.bnibrasil.com.br/api/v1`, auth header
  `X-N8N-API-KEY: <api-key>`. **Verified working** with the provided key.
- **Native MCP server** — `https://n8n.bnibrasil.com.br/mcp-server/http`
  (Streamable HTTP), auth `Authorization: Bearer <MCP-Access-Token>`.

## Public REST API — endpoints verified on this instance

All returned HTTP `200` with the provided key:

| Endpoint                          | Purpose                                   |
| --------------------------------- | ----------------------------------------- |
| `GET /workflows`                  | List workflows (cursor paginated)         |
| `GET /workflows/{id}`             | Get one workflow (full nodes/connections) |
| `POST /workflows`                 | Create workflow                           |
| `PUT /workflows/{id}`             | Update workflow                           |
| `DELETE /workflows/{id}`          | Delete workflow                           |
| `POST /workflows/{id}/activate`   | Activate                                  |
| `POST /workflows/{id}/deactivate` | Deactivate                                |
| `GET /executions`                 | List executions/runs                      |
| `GET /executions/{id}`            | Get one execution (`?includeData=true`)   |
| `DELETE /executions/{id}`         | Delete an execution                       |
| `GET /tags`                       | List tags                                 |
| `GET /variables`                  | List environment variables                |
| `GET /projects`                   | List projects                             |
| `GET /users`                      | List users                                |
| `GET /credentials/schema/{type}`  | Credential type schema (e.g. `n8nApi`)    |

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

### Tags observed

```
SECRETÁRIA, DIRECTUS, GERAL, SISTEMA, CHATWOOT, CORREÇÃO, SUPERVISORA,
ATENDENTE, SDR, SUPORTE, ERROS, ENTREVISTA, CONTRATO
```

## MCP server setup

The native MCP server needs a dedicated **MCP Access Token** — a Public API key is
rejected with `401 Unauthorized` and `WWW-Authenticate: Bearer realm="n8n MCP Server"`
(audience mismatch, by design).

1. In n8n: **Settings → Instance-level MCP → Enable MCP access** (owner/admin).
2. **Connection details → Access Token** → copy the generated token.
3. Wire it into Cursor via `.cursor/mcp.json` at the repo root:

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

4. Verify the token before wiring, using the probe script:

```bash
BNI_N8N_MCP_TOKEN="<token>" scripts/mcp-probe.sh initialize   # expect HTTP 200
```

Only specific workflows are exposed to MCP: mark them **Available in MCP** in n8n.

### Auth quick reference

| Interface        | Header                              | Token type        |
| ---------------- | ----------------------------------- | ----------------- |
| Public REST API  | `X-N8N-API-KEY: <key>`              | Public API key    |
| MCP server       | `Authorization: Bearer <token>`     | MCP Access Token  |

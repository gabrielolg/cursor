---
name: bni-directus
description: Access the BNI Brasil Directus CRM (https://crm.bnibrasil.com.br) via its REST/GraphQL API. Use this skill whenever the user asks to read, query, count, filter, create, update, or delete records in the BNI Brasil CRM — e.g. leads, prospects, groups (grupos), members (membros), activities (atividades), follow-ups, or any Directus collection on that instance.
metadata:
  vendor: BNI Brasil
  product: Directus
  directus_version: "11.17.3"
---

# BNI Brasil — Directus CRM

This skill lets the agent interact with the **BNI Brasil** Directus instance, a headless
CMS/CRM reachable at `https://crm.bnibrasil.com.br`. Authentication uses a **static access
token** sent as a Bearer token on every request.

## When to use

Use this skill when the user wants to:

- Query, count, filter, sort, or paginate records in any BNI Brasil CRM collection
  (`leads`, `prospect`, `prospeccao`, `atividades`, `follow_ups`, `membros`, `grupos`, etc.).
- Inspect the schema (which collections and fields exist and what the current token can see).
- Create, update, or delete records (only if the token's role grants write access).
- Run reports/aggregations (counts, groupings) against the CRM.

## Configuration

Credentials are **never hardcoded** — they are read from the environment:

| Variable             | Required | Description                                       |
| -------------------- | -------- | ------------------------------------------------- |
| `BNI_DIRECTUS_URL`   | no       | Base URL (default `https://crm.bnibrasil.com.br`) |
| `BNI_DIRECTUS_TOKEN` | yes      | Directus static access token                       |

**How to provide them (pick one):**

- Export in your shell profile: `export BNI_DIRECTUS_TOKEN=...`
- Copy `.env.example` to `.env` in this skill folder and fill it in — the script
  auto-loads it and it is **gitignored** (never committed).
- For Cursor **Cloud Agents**, set it as a **Cursor secret** (Dashboard → Secrets) so it
  is injected as an environment variable.

> **Security note:** The static token is a credential — never commit it. If it is ever
> exposed, rotate it in the Directus admin panel (Settings → Access Tokens / the token's
> user) and update the secret.

## How to call the API

Always prefer the helper script — it handles auth, base URL, JSON pretty-printing, and URL
encoding of Directus query brackets (`filter[...]`, `aggregate[...]`).

```bash
# General form (relative path after the base URL; leading slash optional)
scripts/directus.sh GET  "items/leads?limit=5"
scripts/directus.sh GET  "items/leads?aggregate[count]=*"
scripts/directus.sh GET  "server/info"
scripts/directus.sh GET  "collections"
scripts/directus.sh POST "items/leads" '{"lead_primeiro_nome":"Ana","status":"novo"}'
scripts/directus.sh PATCH  "items/leads/<id>" '{"status":"qualificado"}'
scripts/directus.sh DELETE "items/leads/<id>"
```

The script prints the pretty JSON response and exits non‑zero on HTTP errors.

If you cannot run the script, call the REST API directly with curl:

```bash
curl -s -H "Authorization: Bearer $BNI_DIRECTUS_TOKEN" \
  "$BNI_DIRECTUS_URL/items/leads?limit=5"
```

## Directus query cheat sheet

Directus REST endpoints live under the base URL. Key ones:

- `GET /server/info` — instance metadata / version.
- `GET /collections` — list collections. `GET /collections/{collection}` for one.
- `GET /fields/{collection}` — field definitions (types) for a collection.
- `GET /items/{collection}` — read records. `GET /items/{collection}/{id}` for one.
- `POST /items/{collection}` — create. `PATCH /items/{collection}/{id}` — update.
  `DELETE /items/{collection}/{id}` — delete.
- `GET /users/me` — the token owner's user.

Common query parameters (append to `items/...`):

- `fields=a,b,relation.c` — select fields (dot‑notation traverses relations; `*` = all).
- `filter[field][_eq]=value` — filter. Operators: `_eq`, `_neq`, `_in`, `_null`, `_nnull`,
  `_contains`, `_icontains`, `_gt`, `_gte`, `_lt`, `_lte`, `_between`.
  Combine with `filter[_and][0][...]` / `filter[_or][0][...]`.
- `search=term` — full‑text-ish search across searchable fields.
- `sort=field` or `sort=-field` — sort (prefix `-` = descending).
- `limit=N` (`-1` = no limit, subject to server `queryLimit.max`), `offset=N`, `page=N`.
- `aggregate[count]=*`, `aggregate[sum]=field`, `groupBy=field` — aggregation/reporting.
- `meta=filter_count,total_count` — include result metadata.

Example — 10 most recent leads with a status filter:

```bash
scripts/directus.sh GET "items/leads?filter[status][_eq]=novo&sort=-date_created&limit=10&fields=id,lead_primeiro_nome,lead_sobrenome,status,date_created"
```

## Important operational notes

- **Permissions are role‑scoped to the token.** The token may see some collections and not
  others. If you get `FORBIDDEN` / "You don't have permission to access collection", that
  collection is not exposed to this token — don't assume it doesn't exist. When unsure which
  collections/fields are available, first run `scripts/directus.sh GET "collections"` and
  `scripts/directus.sh GET "fields/{collection}"` to introspect.
- **This instance's language default is `pt-BR`** and collection/field names are largely in
  Portuguese (e.g. `lead_primeiro_nome`, `grupo_bni`, `usuario_responsavel`).
- **Be careful with writes/deletes.** Confirm intent before `POST`/`PATCH`/`DELETE`, and
  never bulk‑delete without an explicit request. Reads are safe.
- **GraphQL** is also available at `POST /graphql` (system schema at `/graphql/system`) with
  the same Bearer auth, if a GraphQL query is more convenient.
- **Pagination:** the default page size is 100 and `queryLimit.max` is unlimited on this
  instance, but still paginate large pulls (`limit`/`offset` or `page`) and use
  `aggregate[count]=*` to size a result set before fetching it all.

See `references/collections.md` for the collections observed on this instance and the fields
of the most commonly used ones.

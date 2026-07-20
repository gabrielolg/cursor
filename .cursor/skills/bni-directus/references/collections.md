# BNI Brasil Directus — collections reference

Instance: `https://crm.bnibrasil.com.br` · Directus `11.17.3` · default language `pt-BR`.

> This list reflects the collections visible to the configured token at authoring time.
> Access is **role-scoped**: the token may be able to read the schema of a collection but
> not its items (or vice versa). Always confirm live with:
>
> ```bash
> scripts/directus.sh GET "collections"
> scripts/directus.sh GET "fields/{collection}"
> ```

## User-facing collections observed

```
Admin                              Agendas_de_encontros
Agendas_de_encontros_leads         Grupos_BNI
Grupos_BNI_directus_users          Grupos_BNI_diretores_executivos
Grupos_BNI_embaixadores            Grupos_BNI_equipe_administrativa
Prospeccao                         agendamentos
anfitrioes                         arquivos_ia
arquivos_ia_files                  atendimento
atividades                         comite_afiliacao
conhecimentos_ia                   consumo_servicos
coordenadores_de_afiliacao         coordenadores_de_candidatura
datas_entrada_status               debitos
diretores_consultores              diretores_executivos
diretores_regionais                embaixadores
empresa                            equipe_administrativa
especialidades                     follow_ups
grupos                             implementacao
implementacao_variaveis_globais    leads
leads_telefones_ia                 materiais_treinamento_ia
membros                            membros_grupos
mensagem                           mensagens_padrao
presidentes                        processo_afiliacao
processos_judiciais_candidato      processos_judiciais_empresa
processos_judiciais_socios         prompts_globais
prompts_individuais                prospeccao
prospect                           prospect_prospeccao
qualificacao                       regioes_bni
score_candidato                    score_empresa
score_socios                       secretarios_tesoureiros
socios                             subdominio
telefones_ia                       telefones_ia_mensagens_padrao
telefones_ia_prompts_globais       telefones_ia_prompts_individuais
telefones_ia_templates             telefones_ia_variaveis_globais
templates                          temporizadores
treinamentos_ia                    valores_servicos
variaveis                          variaveis_globais
vice_presidentes                   votos
```

System collections (prefixed `directus_`, e.g. `directus_users`, `directus_files`,
`directus_roles`) also exist and follow standard Directus semantics.

## Fields of commonly used collections

### `leads` (≈13,940 records)

| Field                  | Type        | Notes                          |
| ---------------------- | ----------- | ------------------------------ |
| `id`                   | uuid        | Primary key                    |
| `status`               | string      |                                |
| `date_created`         | timestamp   |                                |
| `date_updated`         | timestamp   |                                |
| `lead_usuario_liga`    | string      |                                |
| `lead_primeiro_nome`   | string      | First name                     |
| `lead_sobrenome`       | string      | Last name                      |
| `lead_telefone`        | bigInteger  | Phone                          |
| `usuario_responsavel`  | uuid        | Owner (directus user)          |
| `grupo_bni`            | integer     | BNI group id                   |
| `whatsapp`             | string      |                                |
| `tipo`                 | string      |                                |
| `grupo_followup`       | alias       | Relation                       |
| `follow_up_id`         | alias       | Relation                       |
| `qualificacao`         | alias       | Relation                       |
| `telefone_ia`          | alias       | Relation                       |
| `grupo_atividades`     | alias       | Relation                       |
| `atividades`           | alias       | Relation                       |

### `prospect`

| Field                | Type      | Notes                 |
| -------------------- | --------- | --------------------- |
| `id`                 | uuid      | Primary key           |
| `status`             | string    |                       |
| `date_created`       | timestamp |                       |
| `date_updated`       | timestamp |                       |
| `nome`               | string    | Name                  |
| `empresa`            | string    | Company               |
| `whatsapp`           | string    |                       |
| `especialidade`      | string    | Specialty             |
| `membro`             | uuid      | Related member        |
| `atividades`         | alias     | Relation              |
| `grupo_prospeccao`   | alias     | Relation              |
| `grupo_atividades`   | alias     | Relation              |
| `prospect_por_prospeccao` | alias | Relation             |

> Fields for other collections (`membros`, `grupos`, etc.) were not readable by the token
> used at authoring time. Introspect them at runtime with
> `scripts/directus.sh GET "fields/{collection}"` once the token has access.

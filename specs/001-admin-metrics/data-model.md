# Data Model — US10 (US1: métricas admin em /usuarios)

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Resumo

Esta feature é **somente leitura agregação**. Não cria tabelas, colunas,
índices ou migrations. Os "dados" aqui são os **valores calculados** expostos
pela página `/usuarios`, derivados de entidades já existentes.

## Entidades de origem (sem alteração de esquema)

### User (`app/models/user.rb`)

| Campo | Tipo | Uso nesta feature |
|---|---|---|
| `id` | integer PK | contagem para "usuários cadastrados" |
| `admin` | boolean (`default: false, null: false`) | autorização (`require_admin`) |
| `created_at` | datetime | não usado nesta US1 |

Relações: `has_many :contacts, dependent: :destroy`.

### Contact (`app/models/contact.rb`)

| Campo | Tipo | Uso nesta feature |
|---|---|---|
| `id` | integer PK | contagem para "contatos totais" |
| `created_at` | datetime | agrupamento por semana da série |
| `user_id` | integer FK | dono; não filtrado nesta visão global de admin |

## Entidade de saída (calculada em memória — não persistida)

### AdminMetrics (PORO, `app/services/admin_metrics.rb`)

| Membro | Tipo | Regra |
|---|---|---|
| `users_count` | integer ≥ 0 | total de contas no sistema |
| `contacts_count` | integer ≥ 0 | total de contatos de todos os usuários |
| `weekly_contacts` | array de 8 itens | `{ label: "dd/mm–dd/mm", total: integer ≥ 0 }`, ordem cronológica crescente, terminando na semana corrente (parcial) |
| `max_weekly_total` | integer ≥ 0 | maior `total` da série; usado para escala das barras (0 quando não há dados → barras vazias) |

### Invariantes verificáveis

- **INV-1**: `weekly_contacts.length == 8` sempre (FR-003/FR-004, SC-002).
- **INV-2**: `weekly_contacts.map(&:total).sum == ` (contatos criados nas últimas
  8 semanas) — nunca maior que `contacts_count`.
- **INV-3**: `users_count` e `contacts_count` são não-negativos e refletem o
  estado no momento do carregamento (FR-005).
- **INV-4**: cada item da série tem `label` e `total`; nenhum item é `nil`.
- **INV-5**: as semanas são intervalos de 7 dias, segunda-feira → domingo,
  sem sobreposição e sem lacuna (R1).

### Fronteira das semanas (R1)

```
[hoje − 7×7 dias …… hoje]  em 8 blocos de 7 dias alinhados à segunda-feira
semana 1 (mais antiga) … semana 8 (corrente, parcial)
```

## Transições de estado

Não aplicável: nenhum estado é persistido ou alterado; a feature é de leitura.

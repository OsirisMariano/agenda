# Data Model — US11 (área admin: casca + dashboard)

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Resumo

Esta feature é de **apresentação e navegação**. Não cria tabelas, colunas, índices ou
migrations. O único dado exibido no dashboard já existe: o objeto calculado
`AdminMetrics` (US10), reusado **sem alteração**.

## Entidades de origem (sem alteração de esquema)

### User (`app/models/user.rb`)

| Campo | Tipo | Uso nesta feature |
|---|---|---|
| `id` | integer PK | contagem em `AdminMetrics#users_count` |
| `name` | string | identificação no **topbar** e link "Admin" na navbar |
| `admin` | boolean (`default: false, null: false`) | autorização (`require_admin`) e visibilidade do link "Admin" |
| `confirmed_at` | datetime | não usado aqui |

Relações: `has_many :contacts, dependent: :destroy`.

### Contact (`app/models/contact.rb`)

| Campo | Tipo | Uso nesta feature |
|---|---|---|
| `id` | integer PK | contagem em `AdminMetrics#contacts_count` |
| `created_at` | datetime | agregação semanal (via `AdminMetrics`) |
| `user_id` | integer FK | dono; não filtrado na visão global de admin |

### AdminMetrics (PORO existente, `app/services/admin_metrics.rb`)

Reusado **como está** (nenhuma mudança). Expõe `users_count`, `contacts_count`,
`weekly_contacts` (8 pontos, `{ label:, total: }`) e `max_weekly_total`. Ver
`specs/001-admin-metrics/data-model.md` para as invariantes já garantidas (INV-1..5).

## Entidades de apresentação (não persistidas)

### Navegação da sidebar (`AdminHelper`)

| Membro | Tipo | Regra |
|---|---|---|
| `admin_nav_items` | array | lista de `{ label:, path:, icon: }` — no mínimo Visão Geral (`/admin`) e Usuários (`/usuarios`); ordem fixa |
| `admin_nav_item` | helper | renderiza `<li>`/link aplicando classe **ativa** quando `current_page?(path)` |
| `admin_breadcrumb` | helper | recebe a trilha (`[["Início", root_path], ["Admin", admin_path]]`) e renderiza o caminho; último item sem link |

### Layout admin (ERB)

| Peça | Arquivo | Papel |
|---|---|---|
| Casca | `layouts/admin.html.erb` | `wrapper` + sidebar + topbar + flash + `yield` + footer |
| Sidebar | `layouts/_admin_sidebar.html.erb` | navegação escura (marca + `admin_nav_items`) |
| Topbar | `layouts/_admin_topbar.html.erb` | toggle (label do checkbox), breadcrumb, menu do usuário |
| Flash | `layouts/_flash.html.erb` | mensagens do Rails (compartilhado com o layout público) |

## Invariantes verificáveis

- **INV-1**: o link "Admin" aparece **se e somente se** `current_user&.admin?` (FR-010,
  SC-003).
- **INV-2**: `/admin` e `/usuarios` renderizam dentro da casca admin (sidebar + topbar
  presentes); as demais telas **não** (FR-001).
- **INV-3**: em cada página admin, **exatamente um** item de navegação está ativo
  (FR-004).
- **INV-4**: os valores do dashboard são **idênticos** aos de `/usuarios` para os mesmos
  dados — ambos vêm do mesmo `AdminMetrics` (FR-009, SC-004).
- **INV-5**: o recolhimento da sidebar não depende de JavaScript (FR-005, SC-005).
- **INV-6**: não-admin (logado ou não) nunca recebe `200` com conteúdo admin de `/admin`
  ou `/usuarios` (FR-011, SC-002).

## Transições de estado

Não aplicável: nenhum estado é persistido ou alterado; a feature é de leitura/render.

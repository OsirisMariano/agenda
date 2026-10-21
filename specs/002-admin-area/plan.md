# Implementation Plan: US11 — Área Admin completa (layout + dashboard)

**Branch**: `feature/us11-area-admin` | **Date**: 2026-10-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-admin-area/spec.md`

## Summary

Dar à área admin um **layout próprio** (casca) — sidebar escura, topbar com
breadcrumb e recolhimento **CSS-only** — aplicado a `/admin` e `/usuarios`, mais um
**dashboard** em `GET /admin` que reusa `AdminMetrics` — e um **link "Admin"** na
navbar pública visível só para admin. Abordagem: novo layout `layouts/admin.html.erb`
com partials (`_admin_sidebar`, `_admin_topbar`) e CSS próprio em
`app/assets/stylesheets/admin.scss`; partial `admin/_admin_metrics.html.erb` extraído
da view atual de `users/index` e reusado pelo dashboard; rota solta `get "admin"`,
`AdminController#index` sob `require_admin`. Zero migrations, zero gems novas, zero
JavaScript novo (CSS-only), AdminLTE 3 como referência visual apenas.

## Technical Context

**Language/Version**: Ruby 3.3.0 (`.ruby-version` → `ruby-3.3`)

**Primary Dependencies**: Rails 7.0.8.6 (stack congelada — PRD §8.5), Bootstrap 5.3.3
(gem `bootstrap ~> 5.2` + `sassc-rails`) + Bootstrap Icons via CDN (já no layout)

**Storage**: PostgreSQL 12.3 — nenhuma leitura/escrita nova além do já existente
`AdminMetrics` (`User.count`, `Contact.count`, agregação semanal). Sem migration.

**Testing**: RSpec (rspec-rails 7.1.1) + shoulda-matchers; helpers customizados
`create_user`/`create_contact`; baseline **255 exemplos**; no container com
`RAILS_ENV=test`

**Target Platform**: Web server (Docker Compose, Puma), browser moderno

**Project Type**: Web application (Rails MVC monolítico — server-rendered, ERB)

**Performance Goals**: layout + dashboard sem custo além do já pago por `/usuarios`
(mesmos agregados); nenhum JS bloqueante novo; CSS estático servido pelo pipeline
Sprockets existente

**Constraints**: sem novas dependências, migrations ou JS (constituição III/V, PRD
§8.5); todo acesso admin sob `require_admin` (FR-011); sidebar CSS-only (FR-005);
specs + PRD na mesma PR (constituição IV); referência visual AdminLTE 3, sem importar
seu CSS/JS

**Scale/Scope**: 1 layout novo + 3 partials novos de layout, 1 controller novo + 1
rota, 1 partial de view extraído, 1 arquivo SCSS novo, ~1 helper de navegação, 1 link
na navbar; specs novos (controller + feature) e ajustes em 2 specs sensíveis ao
layout; ~+20 exemplos (255 → ~275)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Princípio | Status | Nota |
|---|---|---|---|
| I | Isolamento por usuário (NON-NEGOTIABLE) | ✅ | Nenhuma query nova de contato. O dashboard reusa `AdminMetrics`, que já expõe **apenas contagens agregadas** sob `require_admin` — mesmo precedente documentado na US10 (`plan.md` da 001). O layout admin só renderiza conteúdo para admin; nenhum dado de contato individual é exposto. |
| II | Segurança por padrão | ✅ | `AdminController#index` e `/usuarios` usam o `require_admin` existente; não-admin redirecionado sem conteúdo. Sem token/segredo/entrada nova; CSRF e strong params intactos. |
| III | Stack congelada | ✅ | Zero gems novas; Bootstrap 5 + SCSS + ERB nativos; AdminLTE 3 é só referência (nada do BS4/jQuery dele é importado). |
| IV | Test-First / cobertura não-regressiva | ✅ | Specs na mesma PR; baseline 255 → esperado ~275; `rubocop` + `RAILS_ENV=test rspec` verdes obrigatórios; PRD §4.9 + §14 + backlog atualizados na mesma PR. Rede de segurança: 2 specs sensíveis ao header/footer (`footer_spec`, `authentication_spec`) ajustados junto. |
| V | Simplicidade consciente (YAGNI) | ✅ | Layout por partials reusando `_footer` e flash; partial de métricas extraído para não duplicar markup; zero JS (collapse CSS-only); gestão de usuários fica fora (YAGNI). CSS em arquivo separado só pelo tamanho, sem framework. |

**Re-check pós-design (Phase 1):** `data-model.md` não cria entidade; `contracts/`
descreve UI (conteúdo/comportamento, não HTML); nenhuma dependência nova; nenhuma
alteração de esquema. Nenhuma violação a justificar.

## Project Structure

### Documentation (this feature)

```text
specs/002-admin-area/
├── plan.md              # Este arquivo
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   └── admin-ui.md      # Phase 1 — contrato de UI (casca + dashboard)
└── tasks.md             # Phase 2 (/speckit.tasks — ainda não criado)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── admin_controller.rb          # NOVO — index: @metrics = AdminMetrics.new
│   └── users_controller.rb          # index: renderiza dentro do layout admin (sem mudança de dados)
├── helpers/
│   └── admin_helper.rb              # NOVO — destaque do item ativo (nav_item / current_section)
├── services/
│   └── admin_metrics.rb             # existente — reusado como está (US10)
└── views/
    ├── layouts/
    │   ├── admin.html.erb           # NOVO — casca admin (sidebar + topbar + flash + yield + footer)
    │   ├── _admin_sidebar.html.erb  # NOVO — navegação escura (Visão Geral, Usuários)
    │   ├── _admin_topbar.html.erb   # NOVO — toggle CSS-only, breadcrumb, menu do usuário
    │   ├── _flash.html.erb          # NOVO — extraído de application.html.erb (reuso)
    │   └── application.html.erb     # passa a render 'layouts/flash' (sem duplicar)
    ├── admin/
    │   ├── index.html.erb           # NOVO — dashboard /admin
    │   └── _admin_metrics.html.erb  # NOVO — cards + série (extraído de users/index)
    └── users/
        └── index.html.erb           # usa o partial extraído; resto inalterado

config/
└── routes.rb                        # + get "admin", to: "admin#index"

app/assets/stylesheets/
├── application.scss                 # + @import "admin"
└── admin.scss                       # NOVO — wrapper, sidebar escura, topbar, breadcrumb, collapse CSS-only

spec/
├── controllers/
│   └── admin_controller_spec.rb      # NOVO — sucesso p/ admin; redirect p/ não-admin e visitante
├── features/
│   ├── admin_area_spec.rb            # NOVO — casca (sidebar/topbar/ativo) + dashboard + link Admin
│   ├── footer_spec.rb                # ajuste — continua passando no layout admin
│   └── authentication_spec.rb        # ajuste — link Admin visível só p/ admin; dropdown segue
```

**Structure Decision**: monolito Rails já existente — nenhum diretório novo além de
`app/views/admin/`, `app/views/layouts/_admin_*`, `app/controllers/admin_controller.rb`,
`app/helpers/admin_helper.rb` e `app/assets/stylesheets/admin.scss`. Partials de layout
seguem o padrão atual (`layouts/_header`, `layouts/_footer`); partial de view segue o
padrão Bootstrap já usado em `users/index`. Mantém controllers finos e markup sem
duplicação (princípio V).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | Nenhuma violação de constituição a justificar (ver Constitution Check) |

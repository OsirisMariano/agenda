---

description: "Task list for US11 — área admin (casca + dashboard)"
---

# Tasks: US11 — Área Admin completa (layout + dashboard)

**Input**: Design documents from `/specs/002-admin-area/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/admin-ui.md](./contracts/admin-ui.md)

**Tests**: Obrigatórios — critério de aceite transversal do projeto (specs na mesma PR,
cobertura nunca regredindo de **255 exemplos**) e constituição IV.

**Organization**: Três user stories priorizadas — US1 (casca, P1) é o MVP; US2
(dashboard, P2) e US3 (link "Admin", P3) incrementam sobre a US1.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos distintos, sem dependência)
- **[US1]/[US2]/[US3]**: user story da tarefa
- Caminhos de arquivo concretos em cada tarefa

## Path Conventions

Monolito Rails na raiz do repositório (`app/`, `config/`, `spec/`), conforme `plan.md`.

---

## Phase 1: Setup

**Purpose**: Ferramentas e ambiente prontos para trabalhar.

- [x] T001 Verificar containers de pé: `docker compose up -d` (Postgres 12.3 + web)
- [x] T002 [P] Garantir base de teste carregada: `docker compose exec web sh -c 'RAILS_ENV=test bin/rails db:create db:schema:load'`

---

## Phase 2: Foundational

**Purpose**: Nada de infra nova. `AdminMetrics`, `require_admin`, `current_user.admin?`
e os layouts/partials existentes já cobrem tudo.

- [x] T003 Confirmar pré-condições: `require_admin` em `app/controllers/application_controller.rb`, `AdminMetrics#*` em `app/services/admin_metrics.rb`, `layouts/_footer.html.erb` e o logotipo/navbar em `layouts/_header.html.erb`

---

## Phase 3: User Story 1 - Casca admin: layout com navegação (Priority: P1) 🎯 MVP

**Goal**: `/usuarios` (e demais telas admin) passam a renderizar num layout próprio:
sidebar escura com navegação, topbar com breadcrumb e item ativo, recolhimento
CSS-only, rodapé reusado.

**Independent Test**: Logar como admin, abrir `/usuarios` e ver a casca (sidebar
escura, topbar, breadcrumb, item "Usuários" ativo); navegar entre os itens sem sair
do layout; acionar o toggle sem JS.

### Tests for User Story 1 (escrever primeiro; devem falhar antes do código)

- [x] T004 [P] [US1] Spec de feature `spec/features/admin_area_spec.rb` — casca como admin em `/usuarios`: sidebar com marca e itens "Visão Geral"/"Usuários", topbar com breadcrumb, item da página ativa, rodapé presente (A1/A4 do contrato; INV-2/INV-3)
- [x] T005 [P] [US1] No mesmo arquivo, cenário de toggle CSS-only: existe o checkbox/label de recolher (`input#admin-sidebar-toggle` + `label`) — sem depender de JS (A3/FR-005)
- [x] T006 [P] [US1] Ajustar `spec/features/footer_spec.rb` e `spec/features/authentication_spec.rb` para continuarem válidos com o novo layout admin/marcação do header (rodapé e dropdown seguem funcionando)

### Implementation for User Story 1

- [x] T007 [US1] Extrair o bloco de flash de `app/views/layouts/application.html.erb` para `app/views/layouts/_flash.html.erb` e renderizar `render 'layouts/flash'` nos dois layouts (R7)
- [x] T008 [US1] Criar helper `app/helpers/admin_helper.rb` — `admin_nav_items` (Visão Geral → `/admin`, Usuários → `/usuarios`), `admin_nav_item(label, path)` (classe ativa via `current_page?`) e `admin_breadcrumb(*items)` (R5/INV-3)
- [x] T009 [US1] Criar `app/views/layouts/_admin_sidebar.html.erb` — sidebar escura com marca + `admin_nav_items` (FR-002)
- [x] T010 [US1] Criar `app/views/layouts/_admin_topbar.html.erb` — label do toggle (hamburger), breadcrumb e menu do usuário com **Sair** (FR-003/FR-005)
- [x] T011 [US1] Criar `app/views/layouts/admin.html.erb` — checkbox de toggle + wrapper (sidebar/topbar/content-wrapper/flash/`yield`) + `render 'layouts/footer'` (FR-001/FR-006)
- [x] T012 [P] [US1] Criar `app/assets/stylesheets/admin.scss` — wrapper, sidebar escura, topbar, breadcrumb e regras do `#admin-sidebar-toggle:checked` (CSS-only); importar em `app/assets/stylesheets/application.scss` (R2/R3)
- [x] T013 [US1] Aplicar o layout: `layout "admin", only: [:index]` em `app/controllers/users_controller.rb` (cadastro segue no layout público) (R4)

**Checkpoint**: US1 funcional e testável isoladamente (MVP da área admin).

---

## Phase 4: User Story 2 - Dashboard `/admin` (Priority: P2)

**Goal**: página inicial de admin em `GET /admin` com os três números (reuso de
`AdminMetrics`) e atalho para a listagem de usuários.

**Independent Test**: Logar como admin, abrir `/admin`, conferir D1/D2/D3 contra
`User.count`/`Contact.count` e usar o atalho para `/usuarios`; não-admin redirecionado.

### Tests for User Story 2

- [x] T014 [P] [US2] Spec de controller `spec/controllers/admin_controller_spec.rb` — `GET #index` como admin: 200 e `assigns(:metrics)` com totais corretos; como usuário comum e sem sessão: redirect para `root_path` sem `@metrics` (A5/A9/INV-6)
- [x] T015 [P] [US2] Em `spec/features/admin_area_spec.rb`, cenário do dashboard: admin em `/admin` vê as métricas, a série de 8 semanas e o atalho para `/usuarios`; e o cenário de 0 contatos (A5/A6)

### Implementation for User Story 2

- [x] T016 [P] [US2] Extrair o bloco de cards + série de `app/views/users/index.html.erb` para `app/views/admin/_admin_metrics.html.erb` (parâmetro `metrics:`) e reusar em `users/index.html.erb` (R6/FR-009)
- [x] T017 [US2] Criar `app/controllers/admin_controller.rb` — `require_admin` + `index` com `@metrics = AdminMetrics.new` (R4/FR-007)
- [x] T018 [US2] Adicionar a rota solta `get "admin", to: "admin#index", as: "admin"` em `config/routes.rb` (R9)
- [x] T019 [US2] Criar `app/views/admin/index.html.erb` — dashboard usando `admin/_admin_metrics` + atalho para `/usuarios` (FR-007/FR-008)

**Checkpoint**: `/admin` funcional dentro da casca; números idênticos a `/usuarios`.

---

## Phase 5: User Story 3 - Descobribilidade: link "Admin" (Priority: P3)

**Goal**: link "Admin" na navbar pública, visível apenas para admin.

**Independent Test**: Logar como admin e localizar o link "Admin"; logar como comum e
como visitante e confirmar ausência.

### Tests for User Story 3

- [x] T020 [P] [US3] Em `spec/features/admin_area_spec.rb`, cenários do link: presente e funcional para admin; **ausente** para usuário comum e visitante (A7/A8/SC-003)

### Implementation for User Story 3

- [x] T021 [US3] Adicionar o item "Admin" (`link_to 'Admin', admin_path`) em `app/views/layouts/_header.html.erb`, sob `if current_user.admin?` (R8/FR-010)

**Checkpoint**: área admin alcançável pela UI em 1 clique (SC-001).

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T022 [P] Atualizar `docs/PRD.md` — nova §4.9 (Área Admin), §10.1 (contagem de exemplos), §14 (linha v0.15)
- [x] T023 [P] Atualizar `docs/backlog.md` — US11 → 🟣 `Review`, bump de versão e histórico
- [x] T024 Rodar lint: `docker compose exec web bundle exec rubocop`
- [x] T025 Rodar suíte completa: `docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec'` — cobertura ≥ 255 exemplos, 0 falhas (SC-006)
- [x] T026 [P] Validação manual do `quickstart.md` (casca, dashboard, autorização, 0 contatos)

---

## Dependencies & Execution Order

- **Setup (T001–T002)**: sem dependências.
- **Foundational (T003)**: após Setup — não bloqueia nada novo.
- **US1 (T004–T013)**: após T003. T004/T005/T006 [P] entre si e devem **falhar** antes
  de T007–T013. T007 (flash) e T008 (helper) antes de T009/T010/T011 (partials/layout);
  T012 (CSS) em paralelo com a marcação; T013 (aplicar layout) por último.
- **US2 (T014–T019)**: após US1. T014/T015 [P] (specs) falham antes de T016–T019.
  T016 (partial) antes de T019 (dashboard) e antes de T015 ficar verde; T017/T018
  habilitam o endpoint.
- **US3 (T020–T021)**: após US1 (independente de US2). T020 falha antes de T021.
- **Polish (T022–T026)**: após US3. T022/T023/T026 em paralelo; T024/T025 por último.

## Parallel Opportunities

- T002 isolado.
- T004, T005, T006 juntos (specs da US1).
- T012 (SCSS) em paralelo com T009/T010/T011.
- T014/T015 juntos (specs da US2); T016 isolado antes de T019.
- T022, T023, T026 juntos (docs + validação manual).

## Implementation Strategy

MVP = US1 (casca). US2 e US3 são incrementos independentes sobre ela. Entrega em um PR
`feature/us11-area-admin` → `develop`; a issue da US11 fecha só na release
`develop → main`.

## Notes

- [P] = arquivos distintos, sem dependência.
- Nenhuma migration, gem nova ou JavaScript novo (constituição III/V, spec FR-012).
- Recolhimento da sidebar é CSS-only (checkbox hack) — testável em `rack_test`.
- Reuso de `_footer` e extração de `_flash` — evita duplicação (FR-006).
- Specs no container exigem `RAILS_ENV=test`.

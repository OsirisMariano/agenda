---

description: "Task list for US10 — métricas admin (US1)"
---

# Tasks: US10 — Métricas básicas na área admin (US1)

**Input**: Design documents from `/specs/001-admin-metrics/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/usuarios-metrics.md](./contracts/usuarios-metrics.md)

**Tests**: Obrigatórios — critério de aceite transversal do projeto (specs na
mesma PR, cobertura nunca regredindo de 230 exemplos) e constituição IV.

**Organization**: Uma única user story (US1, P1) — sem fases de US2/US3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos distintos, sem dependência)
- **[US1]**: única user story desta entrega
- Caminhos de arquivo concretos em cada tarefa

## Path Conventions

Monolito Rails na raiz do repositório (`app/`, `spec/`), conforme `plan.md`.

---

## Phase 1: Setup

**Purpose**: Ferramentas e ambiente prontos para trabalhar.

- [x] T001 Verificar containers de pé: `docker compose up -d` (Postgres 12.3 + web)
- [x] T002 [P] Garantir base de teste carregada: `docker compose exec web sh -c 'RAILS_ENV=test bin/rails db:create db:schema:load'`

---

## Phase 2: Foundational

**Purpose**: Não há infra nova a construir. A autorização (`require_admin`), os
modelos `User`/`Contact` e o padrão de PORO em `app/services` já existem.

**Nada a fazer** — se comprovado, a US1 pode começar direto.

- [x] T003 Confirmar que `before_action :require_admin, only: [:index]` está ativo em `app/controllers/users_controller.rb` (FR-006) e que a rota `GET /usuarios` existe

---

## Phase 3: User Story 1 - Admin vê os três números em /usuarios (Priority: P1) 🎯 MVP

**Goal**: A página existente `/usuarios` passa a exibir total de usuários, total
de contatos e série de 8 semanas de contatos criados (vazias = 0).

**Independent Test**: Logar como admin, abrir `/usuarios` e conferir os três
números contra `User.count`/`Contact.count`; logar como não-admin e confirmar
redirect sem números.

### Tests for User Story 1 (escrever primeiro; devem falhar antes do código)

- [x] T004 [P] [US1] Spec unitário do agregador em `spec/services/admin_metrics_spec.rb` — totais corretos, série com exatamente 8 pontos, semana vazia = 0, ordem cronológica, `max_weekly_total`, cenário de 0 contatos (INV-1..INV-5 de `data-model.md`)
- [x] T005 [P] [US1] Spec de controller (estender `spec/controllers/users_controller_spec.rb`) — `GET #index` como admin responde 200 e o corpo contém os três números corretos; como usuário comum e sem sessão continua redirecionando sem exibir números (A1/A4/A5 do contrato)
- [x] T006 [P] [US1] Spec de feature em `spec/features/admin_metrics_spec.rb` — caminho feliz pela tela (`rack_test`): admin abre `/usuarios` e vê os cards e as 8 semanas; não-admin é redirecionado

### Implementation for User Story 1

- [x] T007 [US1] Criar `app/services/admin_metrics.rb` — PORO com `users_count`, `contacts_count`, `weekly_contacts` (8 itens `{label:, total:}` com zeros preenchidos, segunda→domingo) e `max_weekly_total` (R2/R3/R5)
- [x] T008 [US1] Ligar as métricas no `UsersController#index` (`app/controllers/users_controller.rb`) — uma linha `@metrics = AdminMetrics.new`, sem mudar autorização (R5/R6)
- [x] T009 [US1] Renderizar os cards de totais e a série de 8 semanas em `app/views/users/index.html.erb` — Bootstrap já existente, barras em CSS inline, máximo 0 → barras vazias; listagem de usuários inalterada (R4, contrato C1–C3)

**Checkpoint**: US1 funcional e testável isoladamente (MVP).

---

## Phase 4: Polish & Cross-Cutting Concerns

- [x] T010 [P] Atualizar `docs/PRD.md` — nova §4.8 (métricas admin), §10.1 (contagem de exemplos), §14 (linha v0.14)
- [x] T011 [P] Atualizar `docs/backlog.md` — US10 → 🟣 `Review`, bump de versão e histórico
- [x] T012 Rodar lint: `docker compose exec web bundle exec rubocop`
- [x] T013 Rodar suíte completa: `docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec'` — cobertura ≥ 230 exemplos, 0 falhas (SC-005)
- [x] T014 [P] Validação manual do `quickstart.md` (admin vê números; não-admin redirecionado; 0 contatos sem erro)

---

## Dependencies & Execution Order

- **Setup (T001–T002)**: sem dependências.
- **Foundational (T003)**: após Setup — não bloqueia nada novo (infra já existe).
- **US1 (T004–T009)**: após T003.
  - T004/T005/T006 são [P] entre si (arquivos distintos) e devem **falhar** antes de T007–T009.
  - T007 (serviço) antes de T008 (controller) antes de T009 (view) — cadeia de arquivos.
- **Polish (T010–T014)**: após T009. T010/T011/T014 em paralelo; T012/T013 por último.

## Parallel Opportunities

- T002 isolado.
- T004, T005, T006 juntos (specs).
- T010, T011, T014 juntos (docs + validação manual).

## Implementation Strategy

MVP = US1 inteira (única história do escopo). Entrega em um PR
`feature/us10-metricas-admin` → `develop`; issue #33 fecha só na release
`develop → main`.

## Notes

- [P] = arquivos distintos, sem dependência.
- Nenhuma migration e nenhuma gem nova (constituição III / PRD §8.5).
- Semana começa na segunda-feira; semana corrente parcial (R1).
- Specs no container exigem `RAILS_ENV=test`.

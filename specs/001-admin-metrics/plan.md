# Implementation Plan: US10 — Métricas básicas na área admin (US1)

**Branch**: `feature/us10-metricas-admin` | **Date**: 2026-10-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-admin-metrics/spec.md`

## Summary

Adicionar à página admin existente `GET /usuarios` três números somente-leitura:
total de usuários, total de contatos e série de 8 pontos de contatos criados por
semana (semana corrente parcial incluída, vazias = 0). Abordagem: agregação em
PORO de serviço (`app/services`) com SQL agregado puro sobre `contacts.created_at`
e preenchimento de zeros em Ruby; exibição em cards Bootstrap + barras CSS na view
existente. Zero migrations, zero gems novas, zero mudanças de modelo.

## Technical Context

**Language/Version**: Ruby 3.3.0

**Primary Dependencies**: Rails 7.0.8.6 (stack congelada — PRD §8.5), Bootstrap 5.3.3 (já no projeto)

**Storage**: PostgreSQL 12.3 — leitura agregada sobre `users` e `contacts` (sem migration)

**Testing**: RSpec (rspec-rails 7.1.1) + shoulda-matchers; factories customizados
`create_user`/`create_contact`; baseline **230 exemplos**; no container com
`RAILS_ENV=test`

**Target Platform**: Web server (Docker Compose, Puma), browser moderno

**Project Type**: Web application (Rails MVC monolítico)

**Performance Goals**: página `/usuarios` continua carregando como hoje; agregado
em 1 consulta + contagens (escala de app pessoal: dezenas–milhares de contatos)

**Constraints**: sem novas dependências (constituição III / PRD §8.5); números
somente para admin (FR-006); série sempre com 8 pontos (FR-003/FR-004); specs +
PRD na mesma PR (constituição IV)

**Scale/Scope**: 2 usuários novos em `app/services`, 1 controller index alterado,
1 view alterada, 3 arquivos de spec novos/estendidos; ~+15 exemplos

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Princípio | Status | Nota |
|---|---|---|---|
| I | Isolamento por usuário (NON-NEGOTIABLE) | ✅ com interpretação documentada | O princípio governa acesso a **dados de contato** (registros). Aqui saem **apenas contagens agregadas globais**, sob `require_admin` — precedente da própria `/usuarios`, que já lista todos os usuários. Nenhum registro de contato (nome, telefone…) é exposto. |
| II | Segurança por padrão | ✅ | Autorização reaproveitada (`require_admin`, redireciona não-admin); nenhum token/segredo novo; nenhum dado de entrada. |
| III | Stack congelada | ✅ | Zero gems novas; SQL agregado nativo + Bootstrap já presente. |
| IV | Test-First / cobertura não-regressiva | ✅ | Specs na mesma PR; baseline 230 → esperado ~245; `rubocop` + `RAILS_ENV=test rspec` verdes obrigatórios; PRD atualizado na mesma PR. |
| V | Simplicidade consciente (YAGNI) | ✅ | PORO em `app/services` (padrão `ContactsCsvExporter`); sem cache, sem biblioteca de gráfico, sem entidade nova. |

**Re-check pós-design (Phase 1):** nenhum artefato introduz violação — `data-model.md`
não cria entidades; `contracts/` é UI contract; nenhuma dependência nova.

## Project Structure

### Documentation (this feature)

```text
specs/001-admin-metrics/
├── plan.md              # Este arquivo
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   └── usuarios-metrics.md
└── tasks.md             # Phase 2 (/speckit.tasks — ainda não criado)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── users_controller.rb      # index: @metrics = AdminMetrics.new (alteração mínima)
├── services/
│   └── admin_metrics.rb         # NOVO — agregação (totals + weekly_contacts)
└── views/
    └── users/
        └── index.html.erb       # cards de métricas + barras (alteração)

spec/
├── services/
│   └── admin_metrics_spec.rb    # NOVO — unit do agregador
├── controllers/
│   └── users_controller_spec.rb # estendido — números na resposta, zero leak
└── features/
    └── admin_metrics_spec.rb    # NOVO — caminho feliz pela tela (rack_test)
```

**Structure Decision**: monolito Rails já existente — nenhum diretório novo além
de `app/services/admin_metrics.rb` e os specs. Padrão de serviço PORO seguido
de `ContactsCsvExporter`/`ContactsCsvImporter` (princípio V).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | Nenhuma violação de constituição a justificar (ver Constitution Check, princípio I: interpretação registrada, sem violação real) |

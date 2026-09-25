# Backlog do Produto — Agenda

**Versão:** 1.3
**Data:** Setembro 2026
**Fonte:** PRD v0.8 + Avaliação do Product Owner
**Ferramenta de gestão sugerida:** GitHub Projects (Board)

---

## 1. Contexto da Avaliação

| Dimensão | Nota | Comentário |
|----------|------|------------|
| **Valor entregue** | ★★★★☆ | Problema central resolvido: CRUD privado de contatos com busca/ordenação/paginação |
| **Qualidade técnica** | ★★★★☆ | 93 specs verdes, isolamento por usuário correto, strong params, Docker ok |
| **Documentação** | ★★★★★ | PRD v0.8 alinhado ao código, histórico de versões disciplinado |
| **Segurança** | ★★★★☆ | Recuperação de senha, rate limit e CI em place; falta confirmação de e-mail (US09) |
| **Infra/CI** | ★★★★☆ | GitHub Actions (rspec + rubocop) verde nos PRs desde v0.4 |
| **Débito técnico** | Baixo | Legado saneado em v0.8 (sem resíduo Devise, sem mocks de UI) |

**Risco principal:** usuário que perde os dados fica preso à plataforma — mitigado pela US06 (exportar/importar).
**Risco secundário:** sem confirmação de e-mail, contas falsas são fáceis de criar — endereçado pela US09 (P2).

> **Atualização (set/2026, v1.3):** US05 concluída em v0.8 (issue #28): `devise.en.yml` removido e footer saneado (sem newsletter mock, sem redes sociais `#`, sem "Ajuda"/"Privacidade"). P0 100% entregue; P1 restante = US06 (8 SP). Base verde: **93 exemplos**.

---

## 2. Backlog Priorizado (para o dev contratado)

> **Velocidade assumida:** ~15–20 SP/sprint (dev solo, sprint de 2 semanas).
> **Total inicial:** ~63 SP → ~4 sprints para fechar P0+P1. **Restante (pós-P0):** ~50 SP → ~3 sprints; P2 segue como roadmap contínuo.
> **Status pós-v0.8:** P0 fechado; P1 restante = US06 (8 SP) → ~1 sprint para fechar P1.

### 🔴 P0 — Crítico (Sprint 1–2)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US01 | Como usuário, quero **recuperar minha senha por e-mail** para não perder acesso à conta | Segurança | 8 | ✅ v0.5 (#26/#38) |
| US02 | Como ops, quero **CI (GitHub Actions)** rodando rspec + rubocop nos PRs para garantir qualidade | Infra | 5 | ✅ v0.4 (#24/#37) |
| US03 | Como usuário, quero proteção contra **tentativas repetidas de login** (rate limit via rack-attack) | Segurança | 3 | ✅ v0.6 (#25) |

### 🟡 P1 — Importante (Sprint 3–4)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US04 | Como usuário, quero campos extras no contato (**e-mail, endereço, notas**) | Produto | 5 | ✅ v0.7 (#27/#42) — promovido em `main` via PR #43 |
| US05 | Como dev, quero **sanear o legado**: remover `devise.en.yml`, decidir destino do footer (newsletter/social mock) e rodar RuboCop nas migrations antigas | Dívida | 3 | ✅ v0.8 (#28) — `devise.en.yml` removido, footer saneado; lint das migrations coberto pela exclusão `Rails/BulkChangeTable` |
| US06 | Como usuário, quero **exportar/importar contatos (CSV ou vCard)** para não ficar preso à plataforma | Produto | 8 | ⬜ backlog — próxima entrega (quebra em PR-A export / PR-B import / PR-C docs) |

### 🟢 P2 — Desejável (Backlog futuro)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US07 | Como usuário, quero busca mais inteligente (**full-text/pg_search**, tolerante a acentos) | Produto | 5 | ⬜ backlog |
| US08 | Como dev, quero **upgrade Rails 7.0 → 7.1/7.2** (7.0 próximo do fim de suporte) | Infra | 13 | ⬜ backlog |
| US09 | Como usuário, quero confirmação de e-mail no cadastro (evita contas falsas) | Segurança | 5 | ⬜ backlog |
| US10 | Como admin, quero dashboard com métricas básicas (usuários ativos, contatos criados/semana) | Admin | 8 | ⬜ backlog |

---

## 3. Critério de Aceite Transversal (todas as USs)

- Specs atualizadas na mesma PR — cobertura não pode regredir dos **93 exemplos atuais**
- PRD atualizado na mesma PR (seção correspondente + histórico de versões)
- `bundle exec rubocop` e `RAILS_ENV=test bundle exec rspec` verdes (no container: `docker compose exec web sh -c '...'`) antes do PR

---

## 4. Sugestão de Organização no GitHub Projects

- **Template:** Board
- **Colunas:** `Backlog` / `Todo` / `In Progress` / `Review` / `Done`
- **Campos customizados:** `Épico` (dropdown), `SP` (número), `Prioridade` (select: P0/P1/P2)
- **Labels:** `P0` (vermelho), `P1` (amarelo), `P2` (verde)
- **Automação sugerida:** issue aberta → coluna `Todo`; PR vinculada aberta → `In Progress`; PR mergeada → `Done`

---

## 5. Próximos Passos

1. **Release v0.8:** PR `develop → main` (US05 — saneamento do legado) e atualização do board
2. **Próxima entrega:** US06 — exportar/importar contatos em CSV (PR-A export, PR-B import, PR-C docs/release)
3. Manter P2 (US07–US10) como roadmap contínuo; avaliar agendamento da US08 (upgrade Rails) como dívida técnica de segurança

---

## Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 1.3 | Set 2026 | US05 concluída (v0.8, #28), avaliação do PO atualizada (débito técnico baixo), critério transversal para 93 exemplos, próximos passos pós-v0.8 (US06), fonte PRD v0.8 |
| 1.2 | Set 2026 | US04 concluída (v0.7, #42), critério transversal atualizado para 91 exemplos, próximos passos pós-v0.7 (release + US05/US06), fonte PRD v0.7 |
| 1.1 | Ago 2026 | Status das USs (US01–US03 concluídas, US05 parcial), critério transversal atualizado para 77 exemplos, fonte PRD v0.6 |
| 1.0 | Ago 2026 | Catálogo inicial: 10 user stories priorizadas (P0/P1/P2), ~63 SP, critérios de aceite transversais |

---

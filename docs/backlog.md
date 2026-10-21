# Backlog do Produto — Agenda

**Versão:** 1.11
**Data:** Outubro 2026
**Fonte:** PRD v0.14 + Avaliação do Product Owner
**Ferramenta de gestão:** GitHub Projects (Board #65 — "Agenda — Backlog") + milestone "P2 — Roadmap"

---

## 1. Contexto da Avaliação

| Dimensão | Nota | Comentário |
|----------|------|------------|
| **Valor entregue** | ★★★★☆ | Problema central resolvido: CRUD privado de contatos com busca/ordenação/paginação |
| **Qualidade técnica** | ★★★★☆ | 255 specs verdes, isolamento por usuário correto, strong params, Docker ok |
| **Documentação** | ★★★★★ | PRD v0.13 alinhado ao código, histórico de versões disciplinado |
| **Segurança** | ★★★★☆ | Recuperação de senha, rate limit e confirmação de e-mail (US09, v0.13) em place; CI ativo. Risco de EOL da stack aceito e documentado (PRD §8.5) |
| **Infra/CI** | ★★★★☆ | GitHub Actions (rspec + rubocop) verde nos PRs desde v0.4 |
| **Débito técnico** | Baixo | Legado saneado em v0.8 (sem resíduo Devise, sem mocks de UI) |

**Risco principal:** usuário que perde os dados fica preso à plataforma — mitigado pela US06 (exportar/importar).
**Risco secundário:** ~~contas falsas fáceis de criar por falta de confirmação de e-mail~~ — **resolvido pela US09 (v0.13)**: token hasheado, expiração 2h, login bloqueado até confirmar.
**Risco aceito (novo):** Rails 7.0.8.6 e PostgreSQL 12.3 estão fora de suporte oficial. Decisão de stack congelada, pois o projeto é legado/educacional — registrado no PRD §8.5.

> **Atualização (set/2026, v1.6):** **Ciclo P1 encerrado e P2 aberto.** A release **v0.10** foi promovida (PR #48, 28/09, `Closes #29`) — a US06 está **100% entregue** e não há mais item de P0 ou P1 pendente. A auditoria entre este arquivo e o board #65 revelou quatro divergências, todas corrigidas no **CHORE-05 (#49)**:
>
> 1. **A stack foi congelada** por decisão do PO, conforme o `README.md`. O upgrade de Rails saiu da sprint: a US08 (#31) foi **retirada da milestone** e mantida aberta em `Backlog`, sem data prevista.
> 2. **A US08 estava mal formulada.** Pedia 7.0 → 7.1/7.2, mas **ambos os alvos já estão EOL** (7.1 em 05/10/2025, 7.2 em 09/08/2026). Se um dia a decisão mudar, o alvo passa a ser **8.1** (segurança até 10/10/2027) e a estimativa sobe de 13 para ~18 SP.
> 3. **A US07 não pode usar `pg_search`.** A gem 2.4.0 exige `activerecord >= 8.0`; a 2.3.7 é a última compatível com Rails 7.0. Pinar uma versão congelada contradiz a decisão. A busca vai de `unaccent` + `pg_trgm` — **zero gem nova**.
> 4. **A US10 já tinha a decisão de papel pronta.** A flag booleana `admin` está em produção (`db/schema.rb:36`, `require_admin`, `/usuarios`) — a promessa do README já está cumprida. A US virou *adicionar métricas a uma área que existe*, sem CanCan/Pundit/gem.
>
> Além disso: o critério de aceite transversal das #30–#33 apontava "~53 exemplos" (número herdado da fase CHORE, copiado em massa) e agora aponta **161**; o PR #42 — único PR no board — foi removido; a milestone #4 "P1 — Importante" (fechada e vazia) foi apagada; e a métrica de uso do export/import ganhou issue própria (#50).
>
> **Próxima entrega: US10 (métricas) → v0.14.**

---

## 2. Backlog Priorizado (para o dev contratado)

> **Velocidade assumida:** ~15–20 SP/sprint (dev solo, sprint de 2 semanas).
> **Total inicial:** ~63 SP → P0 + P1 fechados em 4 sprints. **P2 em curso:** US07 (v0.12) e US09 (v0.13) entregues; resta **US10 (8 SP) → v0.14**. Fora do ciclo: US08 (13 SP).
> **Status pós-v0.13:** P0, P1 e a maior parte do P2 fechadas. Releases **v0.12** e **v0.13** promovidas (PR #55, `Closes #30 #32 #49`).

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
| US06 | Como usuário, quero **exportar/importar contatos em CSV** para não ficar preso à plataforma | Produto | 8 | ✅ **v0.9 + v0.10 (#29, PR #46/#47 + release #48)** — export e import CSV com round-trip, relatório linha+campo, RN01–RN04 e injeção de fórmula neutralizada. Ciclo P1 **encerrado**. vCard fora do v1 (métrica de uso: #50) |

### 🟢 P2 — Desejável (ciclo em curso)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US07 | Como usuário, quero busca que tolera **acentos e erros de digitação** | Produto | 5 | ✅ **v0.12 (#30, PR #55)** — `unaccent` + `pg_trgm`, zero gem nova, sem índice de expressão (`unaccent()` é `STABLE` no PG 12.3) |
| US08 | Como dev, quero **upgrade Rails 7.0 → 8.1** | Infra | 13 | 🔒 **fora do ciclo (#31)** — stack congelada por decisão (PRD §8.5). Sem data prevista; se repriorizado, sobe para P0 |
| US09 | Como usuário, quero confirmação de e-mail no cadastro (evita contas falsas) | Segurança | 5 | ✅ **v0.13 (#32, PR #55)** — token hasheado, expiração 2h, login bloqueado até confirmar |
| US10 | Como admin, quero métricas básicas na área admin **que já existe** | Admin | 8 | ✅ **v0.14 (#33, PR #57)** — três números em `/usuarios` — `AdminMetrics` (PORO), série de 8 semanas com zeros preenchidos, só contagens sob `require_admin`, sem gem nova. Publicada em `main` 20/10/2026 |
| US11 | Como admin, quero uma **área admin completa** com navegação (layout sidebar escura) | Admin | 13 | 🟡 **`Todo`** — v0.15. Casca admin (sidebar dark + topbar + breadcrumb) + dashboard `/admin` + link "Admin" na navbar. **Inspirado** no AdminLTE 3, reimplementado em Bootstrap 5 + ERB + CSS puro (zero jQuery/BS4/JS novo). Extrai partial de métricas |

**Ordem da sprint:** US07 → US09 → US10 **entregues** (v0.12, v0.13 e v0.14). **Próxima: US11 (área admin, v0.15).**

> **Mudanças de escopo aprovadas no CHORE-05:**
> - **US07** deixa de usar `pg_search`. A gem 2.4.0 exige `activerecord >= 8.0`; a 2.3.7 é a última compatível com Rails 7.0 — pinar uma versão congelada contradiz a decisão de stack. Vai de `unaccent` + `pg_trgm`, que já vêm no `postgresql-contrib` da imagem `postgres:12.3`.
> - **US10** não cria área admin nem sistema de papéis. A flag booleana `admin` já está em produção desde v0.x (`db/schema.rb:36`, `require_admin`, rota `/usuarios`) — a promessa do `README.md` já está cumprida. A US virou *adicionar três números a uma tela que já existe*.
> - **US08** saiu da milestone e do ciclo. Ver a decisão completa no corpo da issue #31.

---

## 3. Critério de Aceite Transversal (todas as USs)

- Specs atualizadas na mesma PR — cobertura não pode regredir dos **255 exemplos atuais**
- PRD atualizado na mesma PR (seção correspondente + histórico de versões)
- `bundle exec rubocop` e `RAILS_ENV=test bundle exec rspec` verdes (no container: `docker compose exec web sh -c '...'`) antes do PR

---

## 4. Organização no GitHub Projects (Board #65)

- **Template:** Board — "Agenda — Backlog"
- **Colunas:** `Backlog` / `Todo` / `In Progress` / `Review` / `Done`
- **Campos customizados:** `Épico` (Segurança/Infra/Produto/Dívida/Admin), `SP` (número), `Prioridade` (P0/P1/P2)
- **Labels:** `P0` (vermelho), `P1` (amarelo), `P2` (verde)
- **Itens:** apenas **issues**. PRs não entram como item — o rastreio é feito pela coluna "Linked pull requests" (o PR #42 foi removido por ser o único PR no board, enquanto os #46/#47/#48 nunca entraram)
- **Milestone:** "P2 — Roadmap" agrupa a sprint em curso (18 SP, 3 issues). Itens fora do ciclo ficam **sem milestone** — é assim que a US08 (#31) representa "atrasado sem data prevista"
- **Regra de fechamento:** a issue só fecha na PR de release `develop → main` com `Closes #X` no corpo — merge em `develop` não fecha issue neste repo

---

## 5. Próximos Passos

1. **US07' — busca full-text (v0.12, entregue):** `unaccent` + `pg_trgm` por migration, scope `Contact.search` reescrito com `ILIKE` sobre as colunas sem acento e `word_similarity >= 0.4` como plano B para erro de digitação (medido: erro simples 0.60–0.667, plural 0.50, transposição como `jocao` 0.333–0.375 e por isso de fora).
   - **Sem índice de expressão, e não é escolha nossa:** `unaccent()` é `STABLE`, não `IMMUTABLE`, no PostgreSQL 12.3, então `gin ((unaccent(name)) gin_trgm_ops)` é recusado na criação (`functions in index expression must be marked IMMUTABLE`). O plano original da issue está tecnicamente errado.
   - O que segura a consulta é o índice de `user_id` já existente: o scope herda `current_user.contacts`, o planner recorta por `user_id` e só filtra as linhas do dono. A spec do `EXPLAIN` fixa isso com `enable_seqscan = off`, para o teste não depender do tamanho da tabela.
   - Consequência aceita: o filtro de texto é um *filter* sobre as linhas do usuário, não uma busca indexada. Com a escala de um app pessoal (dezenas a milhares de contatos por conta) o custo é irrelevante. Se um dia virar gargalo, o caminho é uma coluna `name_search` já sem acento mantida por trigger, não gambiarra de índice.
2. **US09 — confirmação de e-mail (v0.13, entregue):** reusou o mailer da US01. As duas armadilhas previstas foram tratadas: `create_user` (`spec/support/factory_helpers.rb`) produz usuário confirmado por padrão, com override `confirmed_at: nil`; e `db/seeds.rb` ganhou `user.update!(confirmed_at: user.confirmed_at || Time.current)` **fora** do bloco, porque `find_or_create_by!` não executa o bloco em registro existente. A terceira armadilha não estava prevista e era a pior: sem backfill, a coluna nova nascia `NULL` para toda conta que já existia e o gate de login trancaria o mundo. A migration faz `UPDATE users SET confirmed_at = created_at WHERE confirmed_at IS NULL`.
   - **Dívida deixada de propósito:** `POST /reenviar-confirmacao` sem rate limit. A receita já existe na US03 (rack-attack, 5/IP/min no login); o natural é 3/IP/min aqui. Saiu do escopo por simplicidade, não por ser inofensivo — ver §12.4 do PRD.
3. **US10 — métricas (v0.14, entregue):** três números na tela de `/usuarios` que já existe. Reaproveitou o `require_admin` atual; nenhuma gem de papel nem de gráfico. `AdminMetrics` (`app/services/admin_metrics.rb`), série de 8 semanas naturais (segunda→domingo), zeros preenchidos em Ruby, barras em CSS inline, **255 exemplos** (de 230). Spec Kit em `specs/001-admin-metrics/`. **Publicada em `main` (PR #57, 20/10/2026); #33 fechada.**
4. **CHORE-05 (#49) —** ✅ **fechada na PR de release (PR #55)** junto com #30 e #32.
5. **Métrica de uso do export/import (#50):** decidir o vCard com dado na mão, antes ou durante o ciclo.
6. **US11 — área admin (v0.15, próxima):** casca admin com sidebar escura + topbar + breadcrumb, dashboard `/admin` e link "Admin" na navbar (só para admins). **Inspirada** no AdminLTE 3, reimplementada no stack atual (Bootstrap 5 + ERB + CSS puro) — zero jQuery, zero BS4, zero JS novo, sem lib de gráfico. Extrai partial de métricas reusado em `/admin` e `/usuarios`. Spec Kit em `specs/002-admin-area/`.

---

## Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 1.11 | Out 2026 | **Sincronização pós-release v0.14 + abertura da US11** — US10 vira ✅ (publicada em `main`, PR #57, #33 fechada) e o cabeçalho/ordem da sprint deixam de dizer "aguardando release". **US11 (área admin, 13 SP) entra como próxima entrega (v0.15):** casca admin inspirada no AdminLTE 3, reimplementada em Bootstrap 5 + ERB + CSS puro. Fonte PRD v0.14 |
| 1.10 | Out 2026 | **Métricas admin entregues (US10 — US1, #33, v0.14)** — `AdminMetrics` (PORO) com três números em `/usuarios`: usuários cadastrados, contatos totais e série de 8 semanas naturais (segunda→domingo, semana corrente parcial), agrupada em SQL e com zeros preenchidos em Ruby (série sempre com 8 pontos); só contagens agregadas sob `require_admin`, sem gem nova nem migration. Cobertura 230 → **255 exemplos**. Spec Kit em `specs/001-admin-metrics/`. US10 → 🟣 `Review`; ainda fecha só na release `develop → main`. Fonte PRD v0.14 |
| 1.9 | Out 2026 | **Sincronização pós-release v0.13** — PR #55 (`develop → main`, 11/10/2026) promoveu v0.12 (US07, #30) e v0.13 (US09, #32); #30, #32 e #49 fechadas. US07 e US09 viram ✅ nas tabelas; AC transversal corrigido de 161 → **230 exemplos**; avaliação (specs, docs, risco de contas falsas) e status da sprint atualizados para pós-v0.13; cabeçalho corrigido de 1.7 → 1.9 (o bump 1.8 tinha ficado só no histórico). Fonte PRD v0.13 |
| 1.8 | Set 2026 | **Confirmação de e-mail entregue (US09, #32, v0.13)** — migration com `confirmed_at`/`confirmation_digest`/`confirmation_sent_at` e **backfill `confirmed_at = created_at`** (sem ele o gate trancaria toda conta existente — o pior jeito de ganhar recurso: quebrando o que funcionava); mailer espelhando a US01; rotas públicas de confirmar e reenviar; login bloqueado até confirmar; `create_user` confirmado por padrão e `db/seeds.rb` com `update!` fora do bloco. Link único e simples: o `GET` confirma direto, sem tela intermediária. **Dívida conscientemente deixada:** reenvio sem rate limit (§12.4 do PRD) — mesma receita do rack-attack da US03, 3 linhas. Cobertura 185 → **230 exemplos**. Fonte PRD v0.13 |
| 1.7 | Set 2026 | **Busca full-text entregue (US07, #30, v0.12)** — migration habilitando `unaccent` + `pg_trgm` (já no `postgresql-contrib`, zero gem), scope `Contact.search` com acento nas duas direções, `ILIKE` em nome/e-mail, substring no telefone e `word_similarity >= 0.4` para erro de digitação; UI com dica de tolerância a acento. **Plano corrigido:** o índice de expressão `gin ((unaccent(name)) gin_trgm_ops)` da issue é impossível no PostgreSQL 12.3 (`unaccent()` é `STABLE`, não `IMMUTABLE`) — o recorte passa a ser garantido pelo índice de `user_id`, com spec de `EXPLAIN` e `enable_seqscan = off`. Cobertura 161 → **185 exemplos**. Fonte PRD v0.12 |
| 1.6 | Set 2026 | **Higiene do ciclo P2 (CHORE-05, #49)** — release v0.10 promovida (PR #48), ciclo P1 encerrado. Stack **congelada por decisão** conforme o README: US08 (#31) saiu da milestone e do ciclo (e os alvos 7.1/7.2 já estavam EOL — se repriorizada, o alvo passa a ser 8.1 e a estimativa vai a ~18 SP). US07 (#30) reescrita: `pg_search` **descartado** (2.4.0 exige `activerecord >= 8.0`), vai de `unaccent` + `pg_trgm`. US10 (#33): decisão de papel **já resolvida** (flag booleana `admin` em produção). AC transversal das #30–#33 corrigida de ~53 para 161. Issue de métrica criada (#50). Board: #30/#32/#33 em `Todo`, PR #42 removido, milestone #4 apagada, #5 reescrita. Fonte PRD v0.11 |
| 1.5 | Set 2026 | US06 concluída (v0.9 export + v0.10 import, #29): P1 fechado, injeção de fórmula resolvida no parse, PR-C (release) como próximo passo, ciclo P2 aberto com sugestão de US08, critério transversal para 161 exemplos, fonte PRD v0.10 |
| 1.4 | Set 2026 | US06 iniciada (#29): **PR-A entregue** (export CSV — `ContactsCsvExporter`, `GET /contacts/exportar`, BOM UTF-8, 112 exemplos); PR-B (import) e PR-C (release) mapeados nos próximos passos; injeção de fórmula no CSV registrada como decisão em aberto; critério transversal atualizado para 112 exemplos; alerta de milestone (v0.8 já promovida, US06 sai como v0.9), fonte PRD v0.9 |
| 1.3 | Set 2026 | US05 concluída (v0.8, #28), avaliação do PO atualizada (débito técnico baixo), critério transversal para 93 exemplos, próximos passos pós-v0.8 (US06), fonte PRD v0.8 |
| 1.2 | Set 2026 | US04 concluída (v0.7, #42), critério transversal atualizado para 91 exemplos, próximos passos pós-v0.7 (release + US05/US06), fonte PRD v0.7 |
| 1.1 | Ago 2026 | Status das USs (US01–US03 concluídas, US05 parcial), critério transversal atualizado para 77 exemplos, fonte PRD v0.6 |
| 1.0 | Ago 2026 | Catálogo inicial: 10 user stories priorizadas (P0/P1/P2), ~63 SP, critérios de aceite transversais |

---

# Research — US10 (US1: métricas admin em /usuarios)

**Date**: 2026-10-20 | **Plan**: [plan.md](./plan.md)

Não há `NEEDS CLARIFICATION` no Technical Context. As decisões abaixo resolvem
as únicas ambiguidades reais (fronteira de semana, densidade da série, forma de
exibição).

## R1 — O que conta como "semana" na série de 8 pontos

- **Decision**: semana natural de 7 dias começando na **segunda-feira**; a série
  termina na semana corrente (parcial). O rótulo de cada ponto é o intervalo
  `dd/mm–dd/mm`.
- **Rationale**: padrão brasileiro de calendário e UTC do servidor simplifica o
  cálculo (`beginning_of_week` do Ruby já é segunda-feira por padrão). A semana
  corrente parcial é o comportamento esperado de um painel vivo (FR-005 exige
  dado do momento do carregamento).
- **Alternatives considered**:
  - Semana começando no domingo — comum em relatórios PT-BR de calendário, mas
    exigiria ajuste manual e não agrega valor no contexto do produto.
  - Janela móvel de 7 dias contados de hoje (rolling) — produziria rótulos que se
    movem a cada dia e série sem fronteira estável; pior para comparar semanas.

## R2 — Como garantir 8 pontos sempre (inclusive semana vazia)

- **Decision**: buscar as contagens agrupadas por semana no banco e **preencher
  com zero em Ruby**, montando o array de 8 intervalos pré-calculados.
- **Rationale**: SQL `GROUP BY` não cria linha para período sem dados; o
  preenchimento em memória é explícito, testável e não depende de `generate_series`
  (que funcionaria no PG 12.3, mas infla a consulta sem ganho). Atende FR-004 e
  SC-002 por construção.
- **Alternatives considered**:
  - `generate_series` + `LEFT JOIN` no SQL — funciona, porém acopla a solução ao
    dialeto do banco no teste e no código; mais difícil de ler em spec unitária.
  - `2.weeks` etc. por contagem em Ruby iterando todos os contatos — O(n) em
    memória; some com milhares de contatos. Rejeitado.

## R3 — Consulta agregada única vs. várias contagens

- **Decision**: uma consulta agrupada (`GROUP BY date_trunc('week', created_at)`)
  para a série + `User.count` e `Contact.count` para os totais.
- **Rationale**: três números baratos e legíveis; a série usa `date_trunc('week',
  created_at)` (segunda-feira no PostgreSQL) alinhado ao `beginning_of_week` do
  Ruby, evitando conversão de timezone divergente entre banco e app.
- **Alternatives considered**:
  - Carregar todos os contatos e agrupar em Ruby — O(n) de linhas e pior consumo
    de memória; contra o princípio V (escala pessoal, mas sem motivo para gastar).
  - Índice novo em `contacts.created_at` — desnecessário na escala atual e a
    constituição III manda avaliar o custo antes; pode ser avaliado se virar gargalo.

## R4 — Exibição: números primeiro, visualização depois

- **Decision**: três cards Bootstrap com os números em texto (usuários, contatos
  totais, maiores/menores) + série de 8 rótulos/valores com barras proporcionais
  em CSS inline (altura relativa ao máximo; máximo 0 → barras vazias).
- **Rationale**: o requisito é **informação**, não gráfico (spec, Assumptions).
  CSS puro respeita §8.5 (sem lib de gráfico) e não depende de JS, então funciona
  em specs `rack_test` sem driver Selenium.
- **Alternatives considered**:
  - Chartkick/ApexCharts — proibido pela decisão de stack (PRD §8.5).
  - SVG inline — viável, mas mais código e nenhum ganho sobre barras CSS para 8
    valores.
  - Divulgar só um total de 8 semanas (sem série) — perde a informação de
    tendência pedida na US (issue #33).

## R5 — Onde mora a regra de negócio (não no controller)

- **Decision**: um PORO `AdminMetrics` (`app/services/admin_metrics.rb`) expõe
  `users_count`, `contacts_count` e `weekly_contacts` (array de `{label:, total:}`).
- **Rationale**: segue o padrão já adotado (`ContactsCsvExporter`,
  `ContactsCsvImporter`), permite testar a agregação sem HTTP e mantém o
  controller com 1 linha. Princípio V.
- **Alternatives considered**:
  - Métodos no modelo `Contact` (`Contact.weekly_counts`) — espalha regra de
    relatório de admin no modelo central de contatos.
  - Lógica direto no `UsersController#index` — não testável isoladamente e infla
    o controller.

## R6 — Autorização (FR-006)

- **Decision**: manter o `before_action :require_admin, only: [:index]` existente;
  nenhuma linha nova de autorização.
- **Rationale**: comportamento já em produção e coberto por spec; redireciona
  não-admin para a home sem renderizar a view, portanto sem vazar números.
- **Alternatives considered**:
  - Retornar 403 — mudaria comportamento atual sem requisito; rejeitado.

## R7 — Seed e desenvolvimento

- **Decision**: nenhuma mudança em `db/seeds.rb`.
- **Rationale**: o seed já cria admin (`teste@exemplo.com`) e 50 contatos, o que é
  massa suficiente para inspecionar a série manualmente; a série aparece com os
  50 contatos distribuídos na semana corrente, e o comportamento de zeros é
  coberto por specs.
- **Alternatives considered**: distribuir os contatos do seed em 8 semanas para o
  gráfico "ficar bonito" em dev — muda dado de seed e specs que dependem de 50
  contatos sem ganho funcional. Rejeitado.

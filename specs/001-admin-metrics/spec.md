# Feature Specification: US10 — Métricas básicas na área admin (US1)

**Feature Branch**: `feature/us10-metricas-admin`

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: "US10: métricas básicas na área admin existente (usuários cadastrados, contatos das últimas 8 semanas, contatos totais) em /usuarios"

> **Escopo desta especificação:** apenas a **US1 (P1)** — o admin vê os três números
> na página existente de `/usuarios`. A proteção de acesso (não-admin não vaza
> números) é coberta como requisito e cenário de aceite desta mesma história,
> porque já é comportamento em produção da área admin. A visualização em gráfico
> é secundária: os números em texto são o requisito obrigatório.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin vê os três números em /usuarios (Priority: P1)

Como **admin**, quero ver, na tela de listagem de usuários que já existe, três
números sobre a saúde do produto: **usuários cadastrados**, **contatos criados
nas últimas 8 semanas** (série semanal) e **contatos totais** — para acompanhar
o crescimento do Agenda sem ferramenta externa.

**Why this priority**: É o único incremento de valor desta entrega. A área admin
já existe; adicionar três números é o menor passo que dá visibilidade ao produto.
Sem ela, não há nada a testar ou demonstrar.

**Independent Test**: Pode ser testada sozinha: logar com usuário admin, abrir
`/usuarios` e conferir os três números contra a contagem real dos dados.

**Acceptance Scenarios**:

1. **Given** existem 3 usuários e 10 contatos no sistema, **When** o admin abre
   `/usuarios`, **Then** ele vê "usuários cadastrados" = 3 e "contatos totais" = 10.
2. **Given** existem contatos criados em semanas diferentes das últimas 8 semanas,
   **When** o admin abre `/usuarios`, **Then** a série semanal exibe **exatamente
   8 pontos**, contando apenas as criações das últimas 8 semanas (semana corrente
   incluída, mesmo parcial).
3. **Given** uma semana das últimas 8 não teve nenhum contato criado, **When** o
   admin abre `/usuarios`, **Then** essa semana aparece com valor **0** — nunca
   ausente da série.
4. **Given** um usuário comum (não-admin) está logado, **When** ele acessa
   `/usuarios`, **Then** ele é redirecionado e **nenhum dos três números** é
   exibido ou vazado de qualquer forma.
5. **Given** o sistema tem 0 contatos, **When** o admin abre `/usuarios`, **Then**
   os números exibem 0 e a série exibe 8 pontos com valor 0, sem erro de página.
6. **Given** o admin já está logado, **When** ele abre `/usuarios` com dados
   recentes (contato criado há minutos), **Then** os números refletem o dado
   mais recente no momento do carregamento da página (sem dado defasado de
   véspera).

---

### Edge Cases

- Semana corrente é parcial (ainda em andamento): conta as criações até o momento
  do carregamento da página.
- Fronteira de semana: "últimas 8 semanas" = 8 semanas naturais de 7 dias
  terminando na semana corrente (semana começa na segunda-feira — ver Assumptions).
- Sistema recém-instalado (0 usuários além do admin, 0 contatos): página carrega,
  mostra zeros, nada quebra.
- Muitos contatos na mesma semana: a série mostra a soma da semana, não um ponto
  por contato.
- Timestamp de criação do contato: usa o horário do servidor; ocorrências na
  virada da semana contam para a semana em que o registro foi criado.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A página `/usuarios` MUST exibir, visivelmente para o admin, o
  **total de usuários cadastrados** no sistema.
- **FR-002**: A página `/usuarios` MUST exibir o **total de contatos** de todos
  os usuários.
- **FR-003**: A página `/usuarios` MUST exibir uma **série com exatamente 8
  pontos** com a quantidade de contatos criados por semana nas últimas 8 semanas,
  na ordem cronológica (mais antiga → mais recente).
- **FR-004**: Semanas sem criações MUST aparecer com valor **0**; a série MUST
  ter sempre 8 pontos, inclusive com 0 contatos no sistema inteiro.
- **FR-005**: Os números MUST ser calculados **no momento do carregamento** da
  página (sem cache persistido, sem dado defasado).
- **FR-006**: Acesso à página e a qualquer um dos três números MUST ser restrito
  a usuários admin; não-admin MUST ser redirecionado sem ver os números.
- **FR-007**: Exibição MUST funcionar sem dependência de conexão externa ou
  serviço de terceiros (dado 100% do próprio sistema).

### Key Entities *(include if feature involves data)*

- **User (usuário)**: conta do sistema; atributos relevantes aqui: existência
  (para o total) e flag de admin (para autorização). Sem mudança de modelo.
- **Contact (contato)**: registro pertencente a um usuário; atributos relevantes:
  data/hora de criação (alimenta a série das 8 semanas) e dono (alimenta o
  total global). Sem mudança de modelo.

> Nenhuma entidade nova e **nenhuma mudança de dados persistidos**: a feature é
> somente leitura/agregação sobre dados existentes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Ao abrir `/usuarios`, o admin vê os 3 números **corretos** —
  diferença zero em relação à contagem real de usuários e de contatos.
- **SC-002**: A série semanal tem **sempre 8 pontos**; semanas vazias contam
  como 0 (0% de semanas ausentes da série).
- **SC-003**: **0 vazamentos**: em teste automatizado, não-admin nunca obtém
  nenhum dos três números em nenhuma resposta de `/usuarios`.
- **SC-004**: A página continua carregando com sucesso nos cenários extremos
  (0 usuários/0 contatos; um contato criado no último minuto).
- **SC-005**: Cobertura de testes **não regred** dos 230 exemplos atuais
  (critério de aceite transversal do projeto).

## Assumptions

- O papel admin **já existe** (flag na conta) e será reaproveitado — esta feature
  **não** cria sistema de papéis nem novas áreas administrativas.
- "Últimas 8 semanas" = 8 semanas naturais de 7 dias, terminando na semana
  corrente (parcial); **semana começa na segunda-feira** (padrão do projeto).
- Os números são **globais da plataforma** (todos os usuários/contatos), não por
  usuário — é uma visão de admin.
- A série é apresentada primeiro **como números/texto**; qualquer desenho
  (barras, sparkline) é embellishment, não requisito.
- Entrega **sem novas dependências** (stack congelada, PRD §8.5).
- Specs atualizados e PRD atualizado **na mesma PR** (critério de aceite
  transversal do projeto); baseline de 230 exemplos (SC-005).
- Débito conhecido do repo: specs no container exigem `RAILS_ENV=test` (o compose
  fixa `development`).

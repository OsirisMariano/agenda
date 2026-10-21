# Feature Specification: US11 — Área Admin completa (layout + dashboard)

**Feature Branch**: `feature/us11-area-admin`

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: "US11: área admin completa na área admin existente — casca (layout sidebar escura + topbar + breadcrumb) e dashboard `/admin`, inspirada no AdminLTE 3, reimplementada em Bootstrap 5 + ERB + CSS puro"

> **Escopo desta especificação:** **casca admin (US1, P1)** + **dashboard `/admin` (US2, P2)**.
> A **casca** é o layout com sidebar escura, topbar e breadcrumb que dá à área admin
> cara de aplicação administrativa — hoje a área admin é uma tela solta (`/usuarios`)
> sem navegação. O **dashboard** é uma página inicial de admin (`/admin`) que
> reaproveita os números já existentes (`AdminMetrics`). A gestão de usuários
> (promover/despromover admin, ver contatos de terceiros) está **fora de escopo**
> (vira US futura) — YAGNI.
>
> **Referência, não dependência:** o layout é **inspirado** no AdminLTE 3
> (sidebar escura + topbar + content-wrapper + breadcrumb), mas é **reimplementado**
> no stack atual do projeto — **Bootstrap 5 + ERB + CSS puro**. Nada de jQuery,
> Bootstrap 4, Webpack ou biblioteca de gráfico.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Casca admin: layout com navegação (Priority: P1)

Como **admin**, quero que a área admin tenha um **layout próprio** — sidebar escura
com a navegação entre as seções de administração, topbar com o caminho (breadcrumb)
e a identificação — para me orientar dentro da área e não depender de URLs decoradas.

**Why this priority**: É a fundação visual e de navegação da área admin; sem ela, não
há "área" — só uma tela isolada. É o MVP desta entrega.

**Independent Test**: Pode ser testada sozinha: logar como admin, abrir `/usuarios`,
ver a sidebar escura com os itens de navegação, o topbar com o breadcrumb e o link
ativo destacado; navegar entre os itens sem sair do layout.

**Acceptance Scenarios**:

1. **Given** o admin está logado, **When** ele abre `/usuarios`, **Then** a página é
   renderizada dentro do layout admin: **sidebar escura** com os itens de navegação,
   **topbar** com breadcrumb e o item correspondente à página **destacado como ativo**.
2. **Given** o admin está na sidebar, **When** ele aciona um item de navegação,
   **Then** chega à página correspondente e o layout admin **permanece** (sidebar e
   topbar visíveis), com o novo item destacado.
3. **Given** o admin está em qualquer página da área admin, **When** ele usa o botão
   de alternância (hamburger) do topbar, **Then** a sidebar **recolhe/expande** sem
   recarregar a página e sem depender de JavaScript (comportamento CSS).
4. **Given** o admin está logado, **When** ele abre o menu do usuário no topbar,
   **Then** ele vê as ações de conta (incluindo **Sair**) e continua podendo sair.
5. **Given** o layout admin está em uso, **When** a página carrega, **Then** o rodapé
   público permanece (sem quebrar a experiência de logout pelo rodapé).

---

### User Story 2 - Dashboard `/admin` (Priority: P2)

Como **admin**, quero uma **página inicial de admin** (`/admin`) que mostre os números
do produto (usuários cadastrados, contatos totais e a série de 8 semanas) e atalhos
para as seções de administração — para ter uma visão geral ao entrar na área.

**Why this priority**: Entrega o valor "painel de controle" sobre a fundação da US1.
Depende da casca (US1) para existir como página dentro da área.

**Independent Test**: Pode ser testada sozinha: logar como admin, abrir `/admin`,
conferir os números contra a contagem real e usar os atalhos para `/usuarios`.

**Acceptance Scenarios**:

1. **Given** existem usuários e contatos no sistema, **When** o admin abre `/admin`,
   **Then** ele vê **total de usuários**, **total de contatos** e a **série de 8
   semanas** (sempre 8 pontos, semanas vazias = 0), idênticos aos de `/usuarios`.
2. **Given** o admin está em `/admin`, **When** ele aciona o atalho para a listagem de
   usuários, **Then** ele chega a `/usuarios` dentro do layout admin.
3. **Given** o sistema tem 0 contatos, **When** o admin abre `/admin`, **Then** os
   números exibem 0 e a série exibe 8 pontos com valor 0, sem erro de página.

---

### User Story 3 - Descobribilidade: link "Admin" (Priority: P3)

Como **admin**, quero um **link "Admin"** na navegação principal para chegar à área
admin sem digitar a URL — hoje ela é inacessível pela interface.

**Why this priority**: Fecha o ciclo de uso (a área existe, mas ninguém a alcança pela
UI). É pequeno e não bloqueia US1/US2.

**Independent Test**: Pode ser testada sozinha: logar como admin e localizar o link
"Admin"; logar como usuário comum e confirmar que o link **não** aparece.

**Acceptance Scenarios**:

1. **Given** o admin está logado, **When** ele vê a navegação principal, **Then** há um
   link **"Admin"** que leva à área admin (`/admin`).
2. **Given** um usuário comum (não-admin) está logado, **When** ele vê a navegação
   principal, **Then** o link **"Admin"** **não** aparece.
3. **Given** um visitante (não logado) navega no site, **When** ele vê a navegação,
   **Then** o link **"Admin"** **não** aparece.

---

### Edge Cases

- **Não-admin acessa `/admin` diretamente pela URL**: é redirecionado para a home com
  "Acesso negado." e **nenhum número de admin** é exibido (mesma proteção de `/usuarios`).
- **Visitante (sem sessão) acessa `/admin`**: redirecionado, sem vazar conteúdo.
- **Sidebar em tela pequena (mobile)**: a navegação continua acessível (sidebar
  recolhida/off-canvas via o mesmo mecanismo CSS), sem depender de JavaScript.
- **Sem JavaScript disponível**: o layout e o recolhimento da sidebar continuam
  funcionando (CSS-only); apenas os menus que dependem do Bootstrap JS do topbar
  degradam de forma aceitável.
- **0 usuários além do admin / 0 contatos**: `/admin` carrega com zeros, sem erro.
- **Item de navegação ativo**: exatamente o item da página corrente fica destacado —
  nenhum item ou mais de um.

## Requirements *(mandatory)*

### Functional Requirements

**Casca admin (US1)**

- **FR-001**: A área admin MUST ter um **layout próprio** (distinto do layout público),
  aplicado às páginas administrativas (`/admin` e `/usuarios`), com **sidebar** e
  **topbar**.
- **FR-002**: A **sidebar** MUST ser visualmente **escura** e conter a navegação entre
  as seções de administração (no mínimo: Visão Geral → `/admin`; Usuários → `/usuarios`),
  além da marca do produto.
- **FR-003**: O **topbar** MUST exibir o **breadcrumb** (caminho da página) e a
  identificação do usuário logado com acesso às ações de conta (incluindo **Sair**).
- **FR-004**: O layout MUST destacar como **ativo** o item de navegação correspondente
  à página corrente.
- **FR-005**: O layout MUST oferecer um **controle de recolher/expandir** a sidebar que
  funcione **sem JavaScript** (CSS), permanecendo utilizável em telas pequenas.
- **FR-006**: O layout admin MUST reusar o **rodapé público** e as mensagens de flash
  (nenhum comportamento de logout pelo rodapé MUST ser perdido).

**Dashboard (US2)**

- **FR-007**: MUST existir uma página inicial de administração em **`/admin`**, acessível
  pelo layout admin, exibindo: **total de usuários cadastrados**, **total de contatos**
  e a **série de 8 semanas** definida na US10.
- **FR-008**: A página `/admin` MUST oferecer **atalhos** para as demais seções
  administrativas (no mínimo, a listagem de usuários).
- **FR-009**: Os números de `/admin` MUST ser os mesmos já calculados por
  `AdminMetrics` (mesma definição de `/usuarios`) — **sem duplicar lógica**.

**Descobribilidade (US3)**

- **FR-010**: A navegação principal do site MUST exibir um link **"Admin"** que leva à
  área admin, **visível apenas para usuários admin** (não aparece para usuário comum nem
  para visitante).

**Autorização e segurança (transversal)**

- **FR-011**: Todo acesso à área admin (`/admin` e `/usuarios`) MUST ser restrito a
  usuários admin, reaproveitando o `require_admin` existente; não-admin MUST ser
  redirecionado sem ver conteúdo administrativo.
- **FR-012**: A entrega MUST NOT introduzir novas dependências, migrations, biblioteca
  de gráfico ou JavaScript novo (CSS-only) — stack congelada e YAGNI.

### Key Entities *(include if feature involves data)*

- **User (usuário)**: conta do sistema; atributos relevantes: flag `admin`
  (autorização e visibilidade do link) e nome (exibido no topbar). Sem mudança de modelo.
- **AdminMetrics (agregação existente)**: fonte dos três números do dashboard; reusada
  como está, sem alteração. Sem mudança de modelo.

> Nenhuma entidade nova e **nenhuma mudança de dados persistidos**: a feature é de
> apresentação/navegação sobre dados e serviços existentes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um admin alcança qualquer página da área admin **a partir de outra** por
  no máximo **1 clique** de navegação (sidebar/atalho), sem digitar URL.
- **SC-002**: **0 vazamentos**: em teste automatizado, não-admin e visitante **nunca**
  obtêm conteúdo da área admin (`/admin` ou `/usuarios`) — sempre redirecionados.
- **SC-003**: O link "Admin" aparece para **100%** dos admins e para **0%** dos demais.
- **SC-004**: Os números do dashboard batem **exatamente** com os de `/usuarios` para os
  mesmos dados (diferença zero), incluindo o cenário de 0 contatos (8 pontos, sem erro).
- **SC-005**: O recolhimento da sidebar funciona **sem JavaScript** — a área permanece
  utilizável com JS desabilitado.
- **SC-006**: Cobertura de testes **não regred** dos **255 exemplos** atuais
  (critério de aceite transversal do projeto).

## Assumptions

- O papel admin **já existe** (flag na conta) e o `require_admin` é **reaproveitado** —
  esta feature **não** cria sistema de papéis nem permissões novas.
- O **AdminLTE 3 é referência visual**, não dependência: nada do seu CSS/JS/jQuery/BS4
  é importado; o layout é reimplementado em **Bootstrap 5 + ERB + CSS puro** (PRD §4.8,
  §8.5).
- O layout admin **não** substitui o layout público: as telas de login, cadastro,
  contatos, etc. permanecem como estão. Apenas `/admin` e `/usuarios` usam o layout admin.
- **Gestão de usuários** (promover/despromover admin, ver contatos de terceiros) está
  **fora de escopo** — YAGNI; fica para uma US futura.
- O rodapé e as mensagens de flash são reusados/extraídos para evitar divergência entre
  os dois layouts.
- Rotas permanecem **soltas** em pt-BR (`/admin`, `/usuarios`), sem `namespace`.
- Entrega **sem novas dependências, migrations ou JS** (stack congelada, PRD §8.5).
- Specs atualizados e PRD atualizado **na mesma PR** (critério de aceite transversal);
  baseline de **255 exemplos** (SC-006).
- Débito conhecido do repo: specs no container exigem `RAILS_ENV=test`.

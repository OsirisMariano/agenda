# Research — US11 (área admin: casca + dashboard)

**Date**: 2026-10-20 | **Plan**: [plan.md](./plan.md)

Não há `NEEDS CLARIFICATION` no Technical Context. As decisões abaixo resolvem as
ambiguidades reais de implementação (como obter o visual AdminLTE-like no stack
atual, como fazer o collapse sem JS, como aplicar o layout só às telas de admin,
como evitar duplicação de markup).

## R1 — Layout próprio vs. condicional no layout atual

- **Decision**: criar um **layout separado** `app/views/layouts/admin.html.erb` e
  aplicá-lo às telas admin via `layout "admin"` em `AdminController` e `UsersController`
  (ou um `before_action`/`layout` declarativo). O layout público
  `application.html.erb` **não** ganha ramificações de admin.
- **Rationale**: a casca admin tem estrutura radicalmente diferente (sidebar fixa,
  topbar, content-wrapper). Ramificar o layout público com `if admin?` encheria de
  condicionais ambos os caminhos e arriscaria regressões nas telas públicas (login,
  contatos). Layout separado é o padrão Rails e mantém cada um legível (princípio V).
- **Alternatives considered**:
  - `application.html.erb` condicional por controller — mistura duas cascas e torna
    os specs de footer/header frágeis; rejeitado.
  - `content_for`/`yield(:admin_shell)` no layout público — mais acoplamento e menos
    claro que um layout dedicado.

## R2 — Onde mora o visual "AdminLTE 3" (inspiração, não dependência)

- **Decision**: CSS próprio em `app/assets/stylesheets/admin.scss`, importado por
  `application.scss`, definindo `wrapper`, `sidebar` (tema escuro), `topbar`,
  `content-wrapper` e `breadcrumb` **em cima das utilidades do Bootstrap 5** já
  disponíveis. Nada de AdminLTE, Bootstrap 4, jQuery ou Webpack.
- **Rationale**: o AdminLTE 3 é BS4 + jQuery — incompatível com a stack (PRD §8.5,
  constituição III). Copiar o *layout* (proporções, sidebar escura, topbar, breadcrumb)
  em CSS escopado sob `.admin-*` entrega o mesmo resultado visual sem tocar a stack.
  Um arquivo só, escopado, evita colisão com as telas públicas.
- **Alternatives considered**:
  - Embutir o `adminlte.min.css` — arrasta BS4 e quebra o BS5; proibido.
  - Escrever tudo inline na ERB — engessa manutenção e polui as views; rejeitado.
  - CDN de AdminLTE — dependência de rede + conflito de versões de Bootstrap; rejeitado.

## R3 — Recolhimento da sidebar sem JavaScript (FR-005)

- **Decision**: usar o **checkbox hack** CSS puro — um `<input type="checkbox"
  id="admin-sidebar-toggle" class="admin-sidebar-toggle" hidden>` + `<label>` no topbar
  (hamburger). O estado `:checked` recolhe a sidebar e expande o conteúdo via seletores
  CSS (`#admin-sidebar-toggle:checked ~ .admin-wrapper .admin-sidebar { … }`).
- **Rationale**: atende "funciona sem JS" (FR-005, SC-005) e a spec roda em
  `rack_test` (sem driver). O checkbox/label é o mesmo mecanismo que o Bootstrap usa
  para `collapse`, então é familiar e acessível (label com `aria-controls`/`aria-label`).
  Zero linha de JavaScript.
- **Alternatives considered**:
  - Stimulus controller — JS novo (proibido pela spec FR-012); a única controller
    existente (`hello_controller`) nem é usada — não introduzir dependência.
  - `data-bs-toggle="collapse"` do Bootstrap JS — depende do bundle JS; a CSS-only é
    mais robusta para o requisito "sem JS" e para os specs.

## R4 — Aplicar o layout admin sem quebrar as telas públicas

- **Decision**: `AdminController` e `UsersController` declaram `layout "admin"`.
  As demais telas (sessions, users#new/create, contacts, static_pages, password_resets,
  confirmations) continuam com o layout público.
- **Rationale**: `UsersController#new`/`#create` (cadastro) também vive nele — então
  **não** um `layout "admin"` global no controller; usar `layout "admin", only:
  [:index]` no `UsersController` para o cadastro permanecer no layout público.
- **Alternatives considered**:
  - `layout :resolve_layout` com heurística por action — funciona, mas
    `layout "admin", only: [:index]` é mais direto e explícito.
  - Mover `/usuarios` para um `Admin::UsersController` — fora de escopo (rotas soltas
    decididas pelo mantenedor; namespace foi descartado).

## R5 — Breadcrumb e destaque do item ativo

- **Decision**: um helper `app/helpers/admin_helper.rb` com
  `admin_nav_item(label, path)` (aplica classe ativa conforme `current_page?`) e
  `admin_breadcrumb(*items)` (renderiza `Home / Seção / Página`). Os itens de
  navegação da sidebar são uma pequena coleção (`admin_nav_items`) montada no helper.
- **Rationale**: evita repetir `current_page?`/marcação em cada `<li>` da sidebar e
  mantém a sidebar declarativa. Testável por feature spec (item ativo) e mantém
  controllers finos (princípio V).
- **Alternatives considered**:
  - Lógica inline na ERB da sidebar — duplicação a cada item; rejeitado.
  - `nav_link_to` genérico no `ApplicationHelper` — o conceito é exclusivo do admin;
    manter em `AdminHelper` (escopo correto).

## R6 — Extração do partial de métricas (FR-009, sem duplicar)

- **Decision**: extrair o bloco de cards + série de `users/index.html.erb` para
  `app/views/admin/_admin_metrics.html.erb`, recebendo o objeto de métricas
  (ex.: `render "admin/admin_metrics", metrics: @metrics`). `/usuarios` e `/admin`
  passam a usar o mesmo partial.
- **Rationale**: FR-009 exige "sem duplicar lógica"; duplicar markup entre as duas
  telas criaria divergência futura. O partial é apresentação pura sobre
  `AdminMetrics`, então mover não muda comportamento (specs de US10 continuam verdes).
- **Alternatives considered**:
  - Duplicar o markup no dashboard — viola FR-009 e a régua de simplicidade.
  - Helper que devolve HTML — partial ERB é o padrão Rails e mais legível.

## R7 — Reuso do rodapé e das mensagens de flash (FR-006)

- **Decision**: o layout admin renderiza o **mesmo** `layouts/_footer`; as mensagens
  de flash são extraídas para `layouts/_flash.html.erb` e renderizadas nos dois layouts
  (público e admin). O `application.html.erb` passa a usar o partial.
- **Rationale**: evita duas implementações de flash; o rodapé reusado preserva o
  logout por rodapé e os specs `footer_spec`/`authentication_spec`. Baixo risco: o
  markup do flash é idêntico, só movido.
- **Alternatives considered**:
  - Não reusar o rodapé no admin — decisão do mantenedor foi reusar; e perderia o
    comportamento já coberto por spec.
  - Duplicar o flash no layout admin — divergência garantida; rejeitado.

## R8 — Link "Admin" na navbar (FR-010)

- **Decision**: adicionar em `layouts/_header.html.erb` um `<li>` com link "Admin"
  para `admin_path`, protegido por `if current_user.admin?`, ao lado de "Contatos"/
  "Cadastro".
- **Rationale**: fecha a descobribilidade (US3) com uma linha. A verificação usa o
  `current_user` já disponível via `SessionsHelper`. O link não aparece para usuário
  comum nem visitante (SC-003), coberto por feature spec.
- **Alternatives considered**:
  - Colocar no dropdown do usuário em vez da barra — o mantenedor escolheu a navbar;
    e a navbar tem mais visibilidade (SC-001: alcançar a área em 1 clique).
  - Rota nomeada só por path string — usar `admin_path` mantém consistência de helpers.

## R9 — Rotas (soltas, pt-BR)

- **Decision**: `get "admin", to: "admin#index", as: "admin"` em `config/routes.rb`
  (sem `namespace :admin`), mantendo `/usuarios` como está.
- **Rationale**: segue a convenção de rotas soltas pt-BR (constituição, "Rotas e
  nomes") e a decisão do mantenedor; sem `namespace` não há reestruturação de
  controllers nem quebra de specs existentes.
- **Alternatives considered**:
  - `namespace :admin do … end` — reestruturaria `/usuarios` e todos os seus specs;
    fora de escopo.

## R10 — Seeds e desenvolvimento

- **Decision**: nenhuma mudança em `db/seeds.rb`.
- **Rationale**: o seed já cria admin (`teste@exemplo.com`) com 50 contatos — massa
  suficiente para inspecionar visualmente a casca e o dashboard. Comportamento de
  borda (0 contatos) é coberto por specs.
- **Alternatives considered**:
  - Criar mais dados de demonstração — sem ganho funcional; rejeitado (YAGNI).

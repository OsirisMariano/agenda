# Contract — Área Admin (casca + dashboard)

**Feature**: US11 | **Tipo**: UI contract (aplicação web server-rendered)
**Plan**: [../plan.md](../plan.md) | **Data model**: [../data-model.md](../data-model.md)

Este projeto não expõe API pública; o contrato observável desta feature é o conteúdo
renderizado das rotas admin e da navbar pública. É descrito em termos de comportamento
e de **estrutura semântica** (navegação, caminho, itens ativos), não de classes CSS,
para permitir mudança visual sem quebrar o contrato.

## Endpoint 1 — Dashboard admin

```text
GET /admin
```

| Aspecto | Contrato |
|---|---|
| Autenticação | obrigatória (sessão) |
| Autorização | somente usuário com flag `admin` |
| Não-admin (logado) | redireciona para `root_path` com aviso "Acesso negado." — **nenhum número na resposta** |
| Sem autenticação | redireciona para `root_path` com aviso "Acesso negado." (mesmo `require_admin`) |
| Status de sucesso | 200, renderizado **dentro da casca admin** |

### Conteúdo obrigatório (admin, 200)

| Bloco | Rótulo sugerido (pt-BR) | Valor | Fonte |
|---|---|---|---|
| D1 | "Usuários cadastrados" | inteiro ≥ 0 | `AdminMetrics#users_count` |
| D2 | "Contatos totais" | inteiro ≥ 0 | `AdminMetrics#contacts_count` |
| D3 | "Contatos por semana (últimas 8)" | 8 pares rótulo+valor | `AdminMetrics#weekly_contacts` |
| D4 | Atalho para a listagem de usuários | link para `/usuarios` | — |

D1–D3 MUST ser **idênticos** aos exibidos em `/usuarios` para os mesmos dados (FR-009).

## Endpoint 2 — Casca admin aplicada a `/usuarios`

```text
GET /usuarios
```

| Aspecto | Contrato |
|---|---|
| Autorização | inalterada — apenas admin; não-admin redireciona (comportamento US10) |
| Renderização | MUST ocorrer **dentro da casca admin** (sidebar + topbar), e não no layout público |
| Conteúdo de métricas | inalterado em valor; passa a vir do partial compartilhado |

## Estrutura da casca (contrato semântico)

Toda página da área admin MUST conter:

| Elemento | Semântica | Requisito |
|---|---|---|
| Sidebar | região de navegação, visualmente escura, com marca + itens de navegação | FR-002 |
| Itens de navegação | no mínimo "Visão Geral" (`/admin`) e "Usuários" (`/usuarios`) | FR-002 |
| Item ativo | exatamente o item da página corrente destacado | FR-004 |
| Topbar | região superior com caminho (breadcrumb) e identificação do usuário | FR-003 |
| Controle de recolher | alterna sidebar sem JavaScript | FR-005 |
| Rodapé | mesmo rodapé público (inclui logout) | FR-006 |
| Flash | mensagens de flash do Rails | FR-006 |

## Navbar pública (contrato)

| Given | Then | Requisito |
|---|---|---|
| usuário admin logado | navbar exibe link "Admin" → área admin | FR-010 / SC-003 |
| usuário comum logado | navbar **não** exibe link "Admin" | FR-010 / SC-003 |
| visitante | navbar **não** exibe link "Admin" | FR-010 / SC-003 |

## Cenários de aceite (mapeados à spec)

| # | Given | When | Then | Spec |
|---|---|---|---|---|
| A1 | admin logado | abre `/usuarios` | renderiza na casca: sidebar escura, topbar com breadcrumb, item "Usuários" ativo | US1 c.1 |
| A2 | admin na casca | aciona outro item de navegação | chega à página e a casca permanece, novo item ativo | US1 c.2 |
| A3 | admin em página admin | aciona o toggle (sem JS) | sidebar recolhe/expande sem recarregar | US1 c.3 / FR-005 |
| A4 | admin logado | abre o menu do usuário no topbar | vê ações de conta, incl. **Sair** | US1 c.4 |
| A5 | admin logado | abre `/admin` | vê D1/D2/D3 iguais aos de `/usuarios`; atalho D4 para `/usuarios` | US2 c.1/c.2 |
| A6 | 0 contatos | admin abre `/admin` | números 0 e série com 8 pontos = 0, sem erro | US2 c.3 |
| A7 | admin logado | olha a navbar | link "Admin" presente e leva à área admin | US3 c.1 |
| A8 | usuário comum/visitante | olha a navbar | link "Admin" ausente | US3 c.2/c.3 |
| A9 | não-admin/visitante | acessa `/admin` ou `/usuarios` | redirect, **nenhum** conteúdo admin na resposta | FR-011 / SC-002 |

## Não-requisitos do contrato

- Classes CSS, ícones e proporções exatas da sidebar/topbar — livres (inspiração).
- Página de gestão de usuários (promover/despromover admin) — fora de escopo.
- Endpoint JSON/API para métricas — fora de escopo.
- Comportamento com JavaScript habilitado além do Bootstrap já existente — fora do
  escopo do requisito "funciona sem JS".

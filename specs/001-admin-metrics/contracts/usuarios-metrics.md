# Contract — Página de métricas admin (`GET /usuarios`)

**Feature**: US10 / US1 | **Tipo**: UI contract (aplicação web server-rendered)
**Plan**: [../plan.md](../plan.md) | **Data model**: [../data-model.md](../data-model.md)

Este projeto não expõe API pública; o único contrato observável desta feature é
o conteúdo renderizado de `GET /usuarios`. O contrato é descrito em termos de
comportamento e conteúdo, não de HTML/classes, para permitir mudança visual sem
quebrar o contrato.

## Endpoint

```text
GET /usuarios
```

| Aspecto | Contrato |
|---|---|
| Autenticação | obrigatória (sessão) |
| Autorização | somente usuário com flag `admin` |
| Não-admin (logado) | redireciona para `root_path` com aviso "Acesso negado." — **nenhum número na resposta** |
| Sem autenticação | redireciona para `entrar_url` com aviso "Por favor, faça login." |
| Status de sucesso | 200 em `/usuarios` renderizado para admin |

## Conteúdo obrigatório (admin, 200)

A resposta MUST conter, legíveis por humano, os três números:

| Bloco | Rótulo sugerido (pt-BR) | Valor | Fonte |
|---|---|---|---|
| C1 | "Usuários cadastrados" | inteiro ≥ 0 | `User.count` |
| C2 | "Contatos totais" | inteiro ≥ 0 | `Contact.count` |
| C3 | "Contatos por semana (últimas 8)" | 8 pares rótulo+valor | `AdminMetrics#weekly_contacts` |

E MUST listar **exatamente 8** pontos de semana, na ordem mais antiga → mais
recente, com semanas sem criação exibindo `0`.

A resposta MUST NOT expor dados de contato individuais (nome, telefone, e-mail,
endereço, notas) de outros usuários — apenas contagens agregadas.

A listagem de usuários existente (nome, e-mail, perfil) MUST permanecer
inalterada em comportamento.

## Cenários de aceite (mapeados à spec)

| # | Given | When | Then | Spec |
|---|---|---|---|---|
| A1 | 3 usuários, 10 contatos | admin abre `/usuarios` | vê C1=3, C2=10, série com 8 pontos | US1 c.1 |
| A2 | contatos em semanas distintas das últimas 8 | admin abre | 8 pontos; só as últimas 8 semanas contam; semana corrente parcial | US1 c.2 / FR-003 |
| A3 | uma semana das 8 sem criações | admin abre | essa semana = 0, presente na série | US1 c.3 / FR-004 |
| A4 | usuário comum logado | acessa `/usuarios` | redirect, nenhum de C1/C2/C3 na resposta | US1 c.4 / FR-006 |
| A5 | 0 contatos | admin abre | C1/C2 = 0 e 8 pontos = 0, sem erro | US1 c.5 / SC-004 |
| A6 | contato criado há minutos | admin abre | número reflete o instante do carregamento | US1 c.6 / FR-005 |

## Não-requisitos do contrato

- Tipo/formato de gráfico (barras, sparkline, tabela) — livre.
- Endpoint JSON ou API para as métricas — fora do escopo desta US1.
- Exportação das métricas — fora do escopo.
- Métricas por usuário — fora do escopo (visão é global de admin).

# Backlog do Produto — Agenda

**Versão:** 1.0
**Data:** Agosto 2026
**Fonte:** PRD v0.3 + Avaliação do Product Owner
**Ferramenta de gestão sugerida:** GitHub Projects (Board)

---

## 1. Contexto da Avaliação

| Dimensão | Nota | Comentário |
|----------|------|------------|
| **Valor entregue** | ★★★★☆ | Problema central resolvido: CRUD privado de contatos com busca/ordenação/paginação |
| **Qualidade técnica** | ★★★★☆ | 51 specs verdes, isolamento por usuário correto, strong params, Docker ok |
| **Documentação** | ★★★★★ | PRD v0.3 alinhado ao código, histórico de versões disciplinado |
| **Segurança** | ★★★☆☆ | Base sólida, mas sem recuperação de senha nem proteção contra brute-force |
| **Infra/CI** | ★★☆☆☆ | Sem pipeline CI (só Dockerfile); RuboCop em hook local apenas |
| **Débito técnico** | Médio | Resíduos Devise, mocks no footer, código legado sem lint |

**Risco principal:** usuário que perde a senha fica permanentemente bloqueado — impacto direto na retenção.
**Risco secundário:** sem CI, regressões podem entrar despercebidas.

---

## 2. Backlog Priorizado (para o dev contratado)

> **Velocidade assumida:** ~15–20 SP/sprint (dev solo, sprint de 2 semanas).
> **Total:** ~63 SP → ~4 sprints para fechar P0+P1; P2 segue como roadmap contínuo.

### 🔴 P0 — Crítico (Sprint 1–2)

| # | User Story | Épico | SP |
|---|-----------|-------|----|
| US01 | Como usuário, quero **recuperar minha senha por e-mail** para não perder acesso à conta | Segurança | 8 |
| US02 | Como ops, quero **CI (GitHub Actions)** rodando rspec + rubocop nos PRs para garantir qualidade | Infra | 5 |
| US03 | Como usuário, quero proteção contra **tentativas repetidas de login** (rate limit via rack-attack) | Segurança | 3 |

### 🟡 P1 — Importante (Sprint 3–4)

| # | User Story | Épico | SP |
|---|-----------|-------|----|
| US04 | Como usuário, quero campos extras no contato (**e-mail, endereço, notas**) | Produto | 5 |
| US05 | Como dev, quero **sanear o legado**: rodar RuboCop nas migrations antigas, remover `devise.en.yml`, decidir destino do footer (newsletter/social) | Dívida | 3 |
| US06 | Como usuário, quero **exportar/importar contatos (CSV ou vCard)** para não ficar preso à plataforma | Produto | 8 |

### 🟢 P2 — Desejável (Backlog futuro)

| # | User Story | Épico | SP |
|---|-----------|-------|----|
| US07 | Como usuário, quero busca mais inteligente (**full-text/pg_search**, tolerante a acentos) | Produto | 5 |
| US08 | Como dev, quero **upgrade Rails 7.0 → 7.1/7.2** (7.0 próximo do fim de suporte) | Infra | 13 |
| US09 | Como usuário, quero confirmação de e-mail no cadastro (evita contas falsas) | Segurança | 5 |
| US10 | Como admin, quero dashboard com métricas básicas (usuários ativos, contatos criados/semana) | Admin | 8 |

---

## 3. Critério de Aceite Transversal (todas as USs)

- Specs atualizadas na mesma PR — cobertura não pode regredir dos 51 exemplos atuais
- PRD atualizado na mesma PR (seção correspondente + histórico de versões)
- `bundle exec rspec` e `bundle exec rubocop` passando localmente antes do PR

---

## 4. Sugestão de Organização no GitHub Projects

- **Template:** Board
- **Colunas:** `Backlog` / `Todo` / `In Progress` / `Review` / `Done`
- **Campos customizados:** `Épico` (dropdown), `SP` (número), `Prioridade` (select: P0/P1/P2)
- **Labels:** `P0` (vermelho), `P1` (amarelo), `P2` (verde)
- **Automação sugerida:** issue aberta → coluna `Todo`; PR vinculada aberta → `In Progress`; PR mergeada → `Done`

---

## 5. Próximos Passos

1. Definir ferramenta de gestão (GitHub Projects — gratuito, integra com o repo)
2. Onboarding do dev: README + PRD v0.3 (`docs/PRD.md`) como material inicial
3. Refinamento das US01–US03 antes do início da Sprint 1

---

## Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 1.0 | Ago 2026 | Catálogo inicial: 10 user stories priorizadas (P0/P1/P2), ~63 SP, critérios de aceite transversais |

---

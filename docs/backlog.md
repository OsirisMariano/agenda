# Backlog do Produto — Agenda

**Versão:** 1.1
**Data:** Agosto 2026
**Fonte:** PRD v0.6 + Avaliação do Product Owner
**Ferramenta de gestão sugerida:** GitHub Projects (Board)

---

## 1. Contexto da Avaliação

| Dimensão | Nota | Comentário |
|----------|------|------------|
| **Valor entregue** | ★★★★☆ | Problema central resolvido: CRUD privado de contatos com busca/ordenação/paginação |
| **Qualidade técnica** | ★★★★☆ | 77 specs verdes, isolamento por usuário correto, strong params, Docker ok |
| **Documentação** | ★★★★★ | PRD v0.6 alinhado ao código, histórico de versões disciplinado |
| **Segurança** | ★★★☆☆ | Base sólida, mas sem recuperação de senha nem proteção contra brute-force |
| **Infra/CI** | ★★☆☆☆ | Sem pipeline CI (só Dockerfile); RuboCop em hook local apenas |
| **Débito técnico** | Médio | Resíduos Devise, mocks no footer, código legado sem lint |

**Risco principal:** usuário que perde a senha fica permanentemente bloqueado — impacto direto na retenção.
**Risco secundário:** sem CI, regressões podem entrar despercebidas.

> **Atualização (ago/2026, v1.1):** a avaliação acima é o snapshot inicial. US01 (recuperação de senha), US02 (CI) e US03 (rate limit) já estão concluídas — veja os status na seção 2.

---

## 2. Backlog Priorizado (para o dev contratado)

> **Velocidade assumida:** ~15–20 SP/sprint (dev solo, sprint de 2 semanas).
> **Total inicial:** ~63 SP → ~4 sprints para fechar P0+P1. **Restante (pós-P0):** ~50 SP → ~3 sprints; P2 segue como roadmap contínuo.

### 🔴 P0 — Crítico (Sprint 1–2)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US01 | Como usuário, quero **recuperar minha senha por e-mail** para não perder acesso à conta | Segurança | 8 | ✅ v0.5 (#26/#38) |
| US02 | Como ops, quero **CI (GitHub Actions)** rodando rspec + rubocop nos PRs para garantir qualidade | Infra | 5 | ✅ v0.4 (#24/#37) |
| US03 | Como usuário, quero proteção contra **tentativas repetidas de login** (rate limit via rack-attack) | Segurança | 3 | ✅ v0.6 (#25) |

### 🟡 P1 — Importante (Sprint 3–4)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US04 | Como usuário, quero campos extras no contato (**e-mail, endereço, notas**) | Produto | 5 | ⬜ backlog |
| US05 | Como dev, quero **sanear o legado**: rodar RuboCop nas migrations antigas, remover `devise.en.yml`, decidir destino do footer (newsletter/social) | Dívida | 3 | ⚠️ parcial (#28) — lint feito online; falta `devise.en.yml` + decisão do footer |
| US06 | Como usuário, quero **exportar/importar contatos (CSV ou vCard)** para não ficar preso à plataforma | Produto | 8 | ⬜ backlog |

### 🟢 P2 — Desejável (Backlog futuro)

| # | User Story | Épico | SP | Status |
|---|-----------|-------|----|--------|
| US07 | Como usuário, quero busca mais inteligente (**full-text/pg_search**, tolerante a acentos) | Produto | 5 | ⬜ backlog |
| US08 | Como dev, quero **upgrade Rails 7.0 → 7.1/7.2** (7.0 próximo do fim de suporte) | Infra | 13 | ⬜ backlog |
| US09 | Como usuário, quero confirmação de e-mail no cadastro (evita contas falsas) | Segurança | 5 | ⬜ backlog |
| US10 | Como admin, quero dashboard com métricas básicas (usuários ativos, contatos criados/semana) | Admin | 8 | ⬜ backlog |

---

## 3. Critério de Aceite Transversal (todas as USs)

- Specs atualizadas na mesma PR — cobertura não pode regredir dos 77 exemplos atuais (80 com a US03)
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
| 1.1 | Ago 2026 | Status das USs (US01–US03 concluídas, US05 parcial), critério transversal atualizado para 77 exemplos, fonte PRD v0.6 |
| 1.0 | Ago 2026 | Catálogo inicial: 10 user stories priorizadas (P0/P1/P2), ~63 SP, critérios de aceite transversais |

---

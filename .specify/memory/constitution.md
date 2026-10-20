# Agenda Constitution

## Core Principles

### I. Isolamento por usuário (NON-NEGOTIABLE)

Todo acesso a dados de contatos MUST passar por `current_user.contacts`. Nunca
MUST existir consulta a contato, exportação, importação ou busca fora do escopo
do usuário autenticado.

- `set_contact` e afins MUST usar `current_user.contacts.find(params[:id])`;
  acessar contato de outra conta MUST resultar em `ActiveRecord::RecordNotFound`.
- Busca (`Contact.search`), exportação CSV e importação CSV MUST herdar o
  recorte por `user_id` antes de qualquer filtro de texto ou processamento.
- Rotas privadas MUST ser protegidas por `before_action :require_logged_in_user`
  (ou `require_admin` para `/usuarios`); sem sessão, redirecionamento para
  `/entrar`.

**Rationale:** privacidade é o compromisso central do produto (PRD §1.2, §8.2).
Segurança na consulta (escopo, não filtro posterior) elimina a classe inteira de
vazamento de dados entre contas.

### II. Segurança por padrão

Credenciais e tokens MUST nunca persistir em claro; comunicação com o usuário
MUST evitar virar oráculo de existência de contas.

- Senhas MUST usar `has_secure_password` (bcrypt); tokens de confirmação e de
  recuperação de senha MUST guardar apenas o digest, com expiração de 2 horas e
  — no caso da confirmação — uso único (digest limpo no mesmo `update!`).
- Mensagens de recuperação, reenvio de confirmação e resposta de rate limit
  MUST ser genéricas: mesma resposta para conta existente e inexistente.
- Rate limit rack-attack MUST proteger `POST /entrar` (5 tentativas/IP/min,
  HTTP 429 + `Retry-After`); endpoints que disparam e-mail MUST receber limite
  equivalente quando a dívida for fechada (ver PRD §12.4).
- CSRF (`csrf_meta_tags`), strong parameters e `filter_parameter_logging` MUST
  permanecer ativos.
- Entrada externa (CSV importado) MUST ser sanitizada no parse — valores com
  prefixo de fórmula (`=`, `+`, `-`, `@`, tab, CR) recebem aspas simples; limites
  de tamanho e encoding UTF-8 MUST ser checados antes da leitura.

**Rationale:** PRD §8 registra as proteções como requisito; as mensagens
genéricas e o token hasheado já foram adotados como padrão nas US01/US09 —
viram regra, não exceção.

### III. Stack congelada

A stack é Ruby 3.3.0, Rails 7.0.8.6, PostgreSQL 12.3, Bootstrap 5.3.3. Nenhuma
dependência nova MUST exigir versões superiores à stack congelada (PRD §8.5).

- Gem nova MUST ser compatível com Rails 7.0; se a única versão viável exigir
  Rails ≥ 8, a feature MUST ser replanejada com recursos nativos (precedente:
  `unaccent` + `pg_trgm` no lugar de `pg_search`).
- O risco de stack fora de suporte é decisão de produto aceita e MUST ser
  mantido documentado no PRD §8.5.
- Reverter a decisão é prerrogativa do PO: issue #31 sobe a P0, alvo Rails 8.1
  + PostgreSQL 16, com o escopo descrito no PRD §8.5.

**Rationale:** projeto legado/educacional sem tráfego não-confiável; congelar a
stack evita esforço de upgrade sem benefício de segurança proporcional e mantém
as escolhas de dependência coerentes.

### IV. Test-First e cobertura não-regressiva (NON-NEGOTIABLE)

Nenhuma mudança MUST ser considerada pronta sem `bundle exec rubocop` e
`RAILS_ENV=test bundle exec rspec` verdes, specs atualizados na mesma PR e
cobertura nunca regredindo.

- Toda US MUST entregar specs novos/atualizados junto com o código — no mesmo
  PR que o comportamento muda.
- O número de exemplos MUST ser ≥ ao da última baseline registrada (161 na
  baseline do ciclo P2; 230 após a US09 — ver PRD §10.1).
- O PRD MUST ser atualizado na mesma PR (seção correspondente + histórico de
  versões); backlog/board MUST acompanhar quando houver mudança de escopo.
- Comportamento de segurança (escopo por usuário, token, rate limit, sanitização)
  MUST ter spec de regressão antes de ser alterado.

**Rationale:** critério de aceite transversal do backlog §3; sem ele a cobertura
degrada silenciosamente e docs e código se desalinham.

### V. Simplicidade consciente (YAGNI)

Implementação MUST escolher a solução mais simples que resolve o caso atual;
complexidade MUST ser justificada por requisito real, não por antecipação.

- Lógica extraída de controllers MUST virar PORO em `app/services` (precedente:
  `ContactsCsvExporter`, `ContactsCsvImporter`), testável sem HTTP.
- Gem nova MUST ter justificativa registrada — reuso, segurança ou testing;
  alternativa nativa/standard library MUST ser avaliada primeiro.
- Débito técnico knowingly assumido MUST ser documentado no PRD §12.4 com
  condição de fechamento; débito não registrado é violação de princípio.
- Features fora do escopo v1 (vCard, PDF, papel admin, multi-worker rate limit)
  MUST permanecer fora até decisão explícita do PO.

**Rationale:** o projeto já descartou `pg_search`, upgrade de Rails e sistema de
papéis por essa régua — a simplicidade foi decisiva para entregar os ciclos P1 e
P2 no prazo.

## Restrições Técnicas e de Segurança

- **Idioma:** UI, mensagens, flash, erros e docs do projeto (PRD, backlog, AGENTS,
  specs) MUST permanecer em pt-BR; código e identificadores em inglês.
- **Rotas e nomes:** rotas de usuário seguem o padrão existente (`/entrar`,
  `/sair`, `/cadastro`, `/recuperar-senha`, `/confirmar-email`); helpers em
  snake_case conforme `config/routes.rb`.
- **Migrations:** MUST ser aditivas e reversíveis quando possível; operação de
  backfill em dado existente MUST ser registrada na migration e no PRD (precedente:
  `confirmed_at` na US09). Migrations ficam isentas de `Rails/BulkChangeTable`.
- **Dados:** exportação CSV MUST ser gerada em memória, nunca gravada no servidor
  (RN05); importação MUST preservar linhas válidas mesmo com linhas inválidas
  (RN04) e MUST nunca sobrescrever ou apagar contatos existentes (RN01/RN02).
- **Auditoria de consulta:** queries com filtro de texto sobre contatos MUST
  preservar o recorte por `user_id` (índice existente); qualquer otimização de
  índice MUST respeitar limitações da stack (ex.: `unaccent()` é `STABLE` no
  PG 12.3).
- **Ambiente:** configuração MUST usar `.env` a partir de `.env_example`; specs no
  container MUST rodar com `RAILS_ENV=test` (o compose fixa `development`).

## Fluxo de Desenvolvimento e Quality Gates

- **Git flow:** `feature/*` → `develop`; releases promovem `develop` → `main` via
  PR. Force-push e deleção de branch ficam bloqueados em `main` e `develop`.
- **Gate de qualidade:** os checks de CI `lint` (rubocop) e `test` (rspec) são o
  gate obrigatório em `main` e `develop` (`strict: true`). Revisão aprovadora NÃO
  é exigida — repo de mantenedor único; não reativar "Require a pull request
  review" sem segundo revisor real.
- **Fechamento de issue:** issue só fecha na PR de release `develop → main` com
  `Closes #X`; merge em `develop` não fecha issue. Labels P0/P1/P2 e milestones
  vivem no board GitHub; `docs/backlog.md` espelha o status.
- **Specs de comportamento:** feature specs em `rack_test` por padrão, JS apenas
  quando necessário (`selenium_chrome_headless`); autenticação em controller specs
  por `session[:user_id]` (sem helpers de Devise — Devise não existe aqui).
- **Documentação:** toda mudança de comportamento MUST atualizar PRD na mesma PR;
  mudança de escopo MUST atualizar backlog/board; aprendizado relevante para
  operação MUST ir para `AGENTS.md`.

## Governance

- Esta constituição suprema sobre práticas locais: conflito entre um princípio e
  uma convenção ad-hoc MUST ser resolvido em favor da constituição, ou a
  constituição MUST ser emendada explicitamente.
- Emendas MUST incluir: diff revisado, Sync Impact Report no topo do ficheiro
  (removido antes do commit), bump de versão semântico e data em ISO `YYYY-MM-DD`:
  MAJOR = remoção/redefinição incompatível de princípio; MINOR = princípio ou
  seção nova/expandida; PATCH = clarificação de texto.
- Ratificação: 2026-10-20 (data da adoção inicial).
- Compliance: cada PR MUST ser verificado contra os princípios I e IV antes do
  merge (CI é o gate); violação conhecida MUST ser registrada como débito no
  PRD §12.4 com condição de fechamento, ou bloqueada.
- Revisão: a constituição MUST ser revisada a cada release `develop → main` e
  sempre que uma decisão do PO alterar stack, escopo ou modelo de segurança
  (precedente: §8.5).
- Guidance de execução em runtime vive no `AGENTS.md`; a constituição define o
  *que* é não-negociável, o `AGENTS.md` explica o *como*.

**Version**: 1.0.0 | **Ratified**: 2026-10-20 | **Last Amended**: 2026-10-20

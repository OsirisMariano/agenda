---
description: Agente principal de desenvolvimento do projeto Agenda — codifica seguindo as convenções do repositório (Rails, pt-BR, RSpec, RuboCop shopify, Rails sem Devise). Use como agente padrão ao trabalhar neste repo.
mode: primary
---

Você é o agente principal de desenvolvimento do projeto **Agenda** (Ruby on Rails 7.0, Ruby 3.3, PostgreSQL, Bootstrap 5), um sistema de gestão privada de contatos pessoais.

Leia `AGENTS.md` na raiz e siga-o como autoridade. Convenções críticas do repositório:

- **Idioma:** todo texto de UI, flash, locale, mensagem de erro e comentário em pt-BR. `config.i18n.default_locale` é `:pt-BR`.
- **Auth customizada (sem Devise):** `has_secure_password` com bcrypt; sessão em `session[:user_id]`; "lembrar-me" via `cookies.signed[:user_id]`. EM SPECS autentique com `session[:user_id] = user.id`, nunca helpers do Devise.
- **Contatos escopados:** toda consulta passa por `current_user.contacts`; `set_contact` usa `find(params[:id])` para 404 natural ao acessar contato de outro usuário.
- **Sem FactoryBot:** use os helpers de `spec/support/factory_helpers.rb` (`create_user`/`create_contact`, já incluídos globalmente).
- **Testes/lint:** RSpec + RuboCop (herda `rubocop-shopify`). Rodar SEMPRE no container: `docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec'` e `docker compose exec web bundle exec rubocop`. O compose fixa `RAILS_ENV=development`, então nunca rode `bundle exec rspec` "cru" no container.
- **Paginação:** Pagy, 12/página, overflow para última página.
- **Telefone:** formato BR validado por `Contact::PHONE_REGEX` `(XX) XXXXX-XXXX` (prefixo internacional opcional, DDD obrigatório).
- **Rate limit:** rack-attack 5 tentativas/1min em `POST /entrar`; nos specs o `rails_helper` já troca o store.
- **Docs:** toda feature atualiza `docs/PRD.md` (seção correspondente + histórico de versões) e `docs/backlog.md` na MESMA PR; cobertura não regride de 91 exemplos.
- **Workflow:** sempre confirme `bundle exec rubocop` e `RAILS_ENV=test bundle exec rspec` antes de considerar um PR pronto.
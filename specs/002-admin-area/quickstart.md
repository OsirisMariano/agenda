# Quickstart — US11 (área admin: casca + dashboard)

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) |
**Contrato**: [contracts/admin-ui.md](./contracts/admin-ui.md)

Guia de validação ponta-a-ponta. Não substitui os specs automatizados — serve para
confirmar manualmente a casca, o dashboard e a descobribilidade.

## Pré-requisitos

- PostgreSQL rodando e `.env` configurado (ver `AGENTS.md`).
- No container, specs **sempre** com `RAILS_ENV=test` (o compose fixa
  `development`).

```sh
docker compose up -d
```

## 1. Preparar dados

```sh
# Base de desenvolvimento com admin + 50 contatos
docker compose exec web bin/rails db:prepare db:seed
```

O seed cria admin `teste@exemplo.com` / `123456`.

## 2. Validar a casca e o dashboard pela tela

1. Acesse `/entrar`, entre com `teste@exemplo.com` / `123456`.
2. Na navbar, confirme o link **"Admin"** e clique nele → abre `/admin`.
3. Confirme a **casca admin**: sidebar escura (Visão Geral / Usuários), topbar com
   **breadcrumb** e o item **"Visão Geral" ativo**.
4. No dashboard, confira os números:
   - **Usuários cadastrados** = `User.count`;
   - **Contatos totais** = `Contact.count`;
   - série com **exatamente 8 semanas** (`dd/mm–dd/mm`), semana corrente parcial;
   - atalho para **Usuários** (`/usuarios`).
5. Clique em **Usuários** na sidebar: a casca permanece e o item **"Usuários"** fica
   ativo; os números de `/usuarios` batem com os do dashboard.
6. Acione o **hamburger** do topbar: a sidebar recolhe/expande **sem recarregar**.
7. Abra o menu do usuário no topbar e confirme **Sair** (e o logout pelo rodapé).

Conferência de contagem (opcional):

```sh
docker compose exec web bin/rails runner 'puts "users=#{User.count} contacts=#{Contact.count}"'
```

## 3. Validar autorização e descobribilidade

1. Saia e entre com um usuário **não-admin**:
   - o link **"Admin"** **não** aparece na navbar;
   - acessar `/admin` (pela URL) redireciona para a home com "Acesso negado." e
     **nenhum** número é exibido;
   - acessar `/usuarios` idem (mesmo comportamento da US10).
2. Sem sessão (janela anônima), acesse `/admin`: redireciona, sem conteúdo admin.

## 4. Validar borda — nenhum contato

```sh
docker compose exec web bin/rails runner '
  Contact.delete_all
  m = AdminMetrics.new
  puts "total=#{m.contacts_count} pontos=#{m.weekly_contacts.length} todos_zero=#{m.weekly_contacts.all? { |w| w[:total].zero? }}"
'
```

Esperado: `total=0 pontos=8 todos_zero=true`. Abra `/admin` e confirme zeros sem erro.

## 5. Validar com testes automatizados

```sh
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/controllers/admin_controller_spec.rb'
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/features/admin_area_spec.rb'
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/features/footer_spec.rb'
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/features/authentication_spec.rb'
```

Depois, a suíte completa + lint (gate de CI):

```sh
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec'
docker compose exec web bundle exec rubocop
```

## Critério de sucesso da validação

- [ ] `/admin` e `/usuarios` renderizam na casca admin (sidebar escura + topbar +
      breadcrumb), com o item ativo correto.
- [ ] O recolhimento da sidebar funciona **sem JavaScript**.
- [ ] Dashboard mostra D1/D2/D3 idênticos a `/usuarios` e atalho para `/usuarios`.
- [ ] Link "Admin" aparece só para admin (0% para comum/visitante).
- [ ] Não-admin/visitante nunca veem conteúdo admin (`/admin`, `/usuarios`).
- [ ] Rodapé (com logout) e flash funcionam no layout admin.
- [ ] Zero contatos → `/admin` carrega com zeros, sem erro.
- [ ] Suíte completa verde e cobertura ≥ 255 exemplos (SC-006).
- [ ] `rubocop` sem offenses.

## Referências

- Comportamento esperado: [contracts/admin-ui.md](./contracts/admin-ui.md)
- Invariantes e apresentação: [data-model.md](./data-model.md)
- Decisões técnicas: [research.md](./research.md)

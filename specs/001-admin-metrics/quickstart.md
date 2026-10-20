# Quickstart — US10 (US1: métricas admin em /usuarios)

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) |
**Contrato**: [contracts/usuarios-metrics.md](./contracts/usuarios-metrics.md)

Guia de validação ponta-a-ponta. Não substitui os specs automatizados — serve
para confirmar manualmente o comportamento e conferir números contra os dados.

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

## 2. Validar pela tela

1. Acesse `/entrar`, entre com `teste@exemplo.com` / `123456`.
2. Abra `/usuarios`.
3. Confira:
   - o card **"Usuários cadastrados"** bate com `User.count` (o próprio badge do
     cabeçalho, que já lista os usuários, serve de conferência rápida);
   - o card **"Contatos totais"** bate com `Contact.count`;
   - a série mostra **exatamente 8 semanas** com rótulos `dd/mm–dd/mm`;
   - a semana corrente aparece **parcial** (os 50 contatos do seed caem nela, se
     você acabou de rodar o seed).
4. Saia e entre com um usuário **não-admin** e acesse `/usuarios`: deve ser
   redirecionado para a home com "Acesso negado." e **não** ver nenhum número.

Conferência de contagem (opcional):

```sh
docker compose exec web bin/rails runner 'puts "users=#{User.count} contacts=#{Contact.count}"'
```

## 3. Validar borda — nenhum contato

```sh
docker compose exec web bin/rails runner '
  Contact.delete_all
  m = AdminMetrics.new
  puts "total=#{m.contacts_count} pontos=#{m.weekly_contacts.length} todos_zero=#{m.weekly_contacts.all? { |w| w[:total].zero? }}"
'
```

Esperado: `total=0 pontos=8 todos_zero=true`.

## 4. Validar com testes automatizados

```sh
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/services/admin_metrics_spec.rb'
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/controllers/users_controller_spec.rb'
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec spec/features/admin_metrics_spec.rb'
```

Depois, a suíte completa + lint (gate de CI):

```sh
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec'
docker compose exec web bundle exec rubocop
```

## Critério de sucesso da validação

- [ ] Admin vê os 3 números corretos na tela.
- [ ] Série sempre com 8 pontos; semana vazia = 0; semana corrente parcial.
- [ ] Não-admin redirecionado e sem números.
- [ ] Zero contatos → página carrega com zeros, sem erro.
- [ ] Suíte completa verde e cobertura ≥ 230 exemplos (SC-005).
- [ ] `rubocop` sem offenses.

## Referências

- Comportamento esperado: [contracts/usuarios-metrics.md](./contracts/usuarios-metrics.md)
- Regras de agregação e invariantes: [data-model.md](./data-model.md)
- Decisões técnicas: [research.md](./research.md)

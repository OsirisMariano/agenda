# PRD - Product Requirements Document

## Agenda - Sistema de Gestão de Contatos

**Versão:** 0.6  
**Data:** Agosto 2026  
**Status:** Lançamento Inicial (v0.6 - Rate limit no login)

---

## 1. Visão Geral do Projeto

### 1.1 Propósito
O **Agenda** é uma aplicação web para gestão de contatos pessoais, permitindo que usuários organizem seus contatos de forma simples, rápida e segura. O projeto foi desenvolvido como uma oportunidade de aprendizado de Ruby on Rails e Bootstrap.

### 1.2 Objetivos
- Permitir cadastro e autenticação de usuários
- Gerenciar contatos pessoais (CRUD completo)
- Garantir privacidade: cada usuário vê apenas seus contatos
- Prover interface responsiva e intuitiva

### 1.3 Público-Alvo
Pessoas físicas que necessitam organizar sua agenda de contatos pessoais com privacidade e acessibilidade.

---

## 2. Stack Tecnológica

| Camada | Tecnologia | Versão |
|--------|------------|--------|
| **Linguagem** | Ruby | 3.3.0 |
| **Framework** | Ruby on Rails | 7.0.8.6 |
| **Frontend** | Bootstrap | 5.3.3 |
| **JavaScript** | Hotwire (Turbo + Stimulus) | Rails 7 native |
| **Database** | PostgreSQL | 12.3 (Docker) |
| **Asset Pipeline** | Importmap + Sprockets | - |
| **Autenticação** | Custom (has_secure_password + bcrypt) | bcrypt 3.1.20 |
| **Rate limit** | rack-attack | 6.8.0 |
| **Testes** | RSpec + Capybara | rspec-rails 7.1.1 |
| **Paginação** | Pagy | 9.4.0 |
| **Servidor** | Puma | 5.6.9 |
| **CI** | GitHub Actions (lint + test) | - |
| **Deploy** | Docker Compose | - |

---

## 3. Arquitetura do Sistema

### 3.1 Padrão Arquitetural
- **MVC (Model-View-Controller)** padrão do Rails
- **RESTful Routes** para recursos principais

### 3.2 Estrutura de Diretórios
```
/app
├── app/
│   ├── controllers/      # Lógica de controle
│   ├── models/           # Modelos de dados (ActiveRecord)
│   ├── views/            # Templates ERB
│   ├── helpers/          # Métodos auxiliares
│   ├── assets/           # CSS/JS
│   ├── javascript/       # Stimulus controllers
│   └── mailers/          # ActionMailer (não usado)
├── config/               # Configurações Rails
├── db/                   # Migrações e schema
├── spec/                 # Testes RSpec
└── public/               # Arquivos estáticos
```

---

## 4. Funcionalidades Implementadas

### 4.1 Autenticação de Usuários

#### Cadastro de Usuário
- **Rota:** `GET /cadastro` → `users#new`
- **Campos:** Nome, E-mail, Senha, Confirmação de Senha
- **Validações:**
  - Nome: obrigatório, máximo 100 caracteres
  - E-mail: obrigatório, único (case insensitive), formato válido
  - Senha: mínimo 6 caracteres
  - Confirmação de senha: obrigatória quando senha presente

#### Login/Logout
- **Rota Login:** `GET /entrar` → `sessions#new`
- **Processamento:** `POST /entrar` → `sessions#create`
- **Logout:** `GET|DELETE /sair` → `sessions#destroy`
- **Armazenamento:** Session cookie (`session[:user_id]`)
- **Método `sign_in(user, remember_me:)`:** Define session ou cookie "Lembrar-me"
- **Método `current_user`:** Recupera usuário da session ou do cookie
- **"Lembrar-me":** Cookie assinado `cookies.signed[:user_id]` com expiração de **2 semanas** (`REMEMBER_ME_EXPIRATION`), removido no logout

#### Admin
- Coluna `admin` (boolean, default `false`) no banco de dados
- `user.admin?` retorna o valor da coluna `admin`
- Apenas usuários com `admin = true` acessam a listagem de usuários (`GET /usuarios`)
- Seed define o usuário `teste@exemplo.com` como admin

### 4.2 Gestão de Contatos (CRUD)

#### Listagem de Contatos
- **Rota:** `GET /contacts` → `contacts#index`
- **Funcionalidades:**
  - Lista apenas contatos do usuário logado
  - **Busca:** Por nome ou telefone (scope `search`, case-insensitive com `ILIKE`)
  - **Ordenação:** Por nome (A-Z) ou data de criação (padrão: nome)
  - **Paginação:** 12 contatos por página (Pagy, overflow para última página)
  - Contador de contatos com badge (total de todos os contatos)

#### Criação de Contato
- **Rota:** `GET /contacts/new` → `contacts#new`
- **Campos:** Nome, Telefone
- **Validações:**
  - Nome: obrigatório, máximo 50 caracteres
  - Telefone: obrigatório, formato brasileiro `(XX) XXXXX-XXXX` (com DDD e código de país opcionais), único por usuário
  - Índice único em `(user_id, phone)` e em `users.email` no banco de dados

#### Edição de Contato
- **Rota:** `GET /contacts/:id/edit` → `contacts#edit`
- **Atualização:** `PATCH /contacts/:id` → `contacts#update`

#### Exclusão de Contato
- **Rota:** `DELETE /contacts/:id` → `contacts#destroy`
- **Confirmação:** Via Turbo confirm (`data-turbo-confirm`)

### 4.3 Páginas Estáticas

- **Home:** `GET /` → `static_pages#index` - Apresentação do sistema com features
- **Sobre:** `GET /sobre` → `static_pages#sobre` - Informações sobre o projeto

### 4.4 Recuperação de Senha 🔑 (RECUPERAÇÃO)

#### Solicitação (`GET/POST /recuperar-senha`)
- Formulário de e-mail na rota `/recuperar-senha`
- Usuário preenche o e-mail da conta e é gerado um **token** (64 bytes hex) + `reset_sent_at` via `create_reset_digest`
- Envio de e-mail (`password_reset`) com link contendo `token` e `email` — vencimento de **2 horas**
- **Mensagem genérica** em ambos os casos (exista ou não a conta) para não revelar e-mails cadastrados

#### Redefinição (`GET/PATCH /recuperar-senha/edit`)
- Token e e-mail chegam na URL (`edit_recuperar_senha_url`)
- `PATCH` valida token (**ainda não expirado**), confirmação de senha e define a nova senha
- Redireciona para o login com flash de sucesso

#### Considerações de Segurança
- Token é um `attr_reader` do objeto `User` (nunca persiste em claro, guarda-se apenas o `digest`)
- `reset_authenticated?` compara com `BCrypt::Password.new(...).is_password?` (token vs digest)
- E-mail de destino **sempre** o da consulta (`params[:email]`), para não vazar para alguém lendo a URL
- `logged_in_user`/admin não interfere: acesso a `/recuperar-senha*` não exige login

### 4.5 Proteção contra Brute-Force (Rate Limit) 🛡️

- **Middleware:** `rack-attack` registrado via `config.middleware.use(Rack::Attack)`
- **Alvo:** `POST /entrar` → `sessions#create`
- **Limite:** 5 tentativas por IP por minuto
- **Resposta:** HTTP 429 com mensagem genérica pt-BR "Muitas tentativas de login. Tente novamente em 1 minuto." (não revela se o e-mail existe) e header `Retry-After: 60`
- **Store:** `Rails.cache` (`:memory_store` em dev/prod; `:null_store` em teste torna o throttle inerte por padrão)
- **Specs:** `spec/requests/rack_attack_spec.rb` cobre bloqueio (429), liberação após a janela de 1 min e não-afetamento de outras rotas
- **Débito documentado:** `:memory_store` é por processo — com múltiplos workers Puma o limite vale por processo (§12.4, revisitar junto da US08)

---

## 5. Modelo de Dados

### 5.1 Diagrama de Entidades

```
┌─────────────────┐           ┌─────────────────┐
│      User       │           │     Contact     │
├─────────────────┤           ├─────────────────┤
│ id              │ 1       N │ id              │
│ name            │◄──────────│ name            │
│ email           │           │ phone           │
│ password_digest │           │ user_id (FK)    │
│ admin (bool)    │           │ created_at      │
│ created_at      │           │ updated_at      │
│ updated_at      │           └─────────────────┘
└─────────────────┘
```

### 5.2 Detalhes dos Modelos

#### User (`app/models/user.rb`)
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :contacts, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }
  
  def admin?
    admin
  end
end
```

**Métodos de recuperação de senha:**
- `create_reset_digest` — gera `reset_token` (64 bytes hex, apenas em memória), atualiza `reset_digest` (hash SHA256) e `reset_sent_at`
- `reset_authenticated?(token)` — compara `BCrypt::Password.new(reset_digest)` com o token recebido
- `reset_expired?` — expira em 2 horas (`reset_sent_at < 2.hours.ago`)
- Colunas: `reset_digest` (string) e `reset_sent_at` (datetime), adicionadas via migration `20260829002247_add_reset_digest_to_users.rb`

#### Contact (`app/models/contact.rb`)
```ruby
class Contact < ApplicationRecord
  PHONE_REGEX = /\A(\+\d{1,3}[-\s.]?)?\(?\d{2}\)?[-\s.]?\d{4,5}[-\s.]?\d{4}\z/

  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :phone, presence: true,
                    format: { with: PHONE_REGEX, message: "inválido. Use o formato (XX) XXXXX-XXXX." },
                    uniqueness: { scope: :user_id }

  scope :search, ->(query) {
    where("name ILIKE :q OR phone ILIKE :q", q: "%#{query}%")
  }
end
```

---

## 6. Rotas da Aplicação

| Método | Caminho | Controller#Action | Nome da Rota |
|--------|---------|-------------------|--------------|
| GET | `/` | static_pages#index | root_path |
| GET | `/sobre` | static_pages#sobre | - |
| GET | `/entrar` | sessions#new | entrar_path |
| POST | `/entrar` | sessions#create | - |
| GET/DELETE | `/sair` | sessions#destroy | sair_path |
| GET | `/cadastro` | users#new | cadastro_path |
| POST | `/users` | users#create | - |
| GET | `/usuarios` | users#index | - |
| GET | `/contacts` | contacts#index | contacts_path |
| GET | `/contacts/new` | contacts#new | new_contact_path |
| POST | `/contacts` | contacts#create | contacts_path |
| GET | `/contacts/:id/edit` | contacts#edit | edit_contact_path |
| PATCH/PUT | `/contacts/:id` | contacts#update | contact_path |
| DELETE | `/contacts/:id` | contacts#destroy | contact_path |
| GET | `/recuperar-senha` | password_resets#new | recuperar_senha_path |
| POST | `/recuperar-senha` | password_resets#create | - |
| GET | `/recuperar-senha/edit` | password_resets#edit | edit_recuperar_senha_path |
| PATCH | `/recuperar-senha` | password_resets#update | - |

---

## 7. Interface do Usuário

### 7.1 Layout Principal (`layouts/application.html.erb`)
- **Header:** Navbar Bootstrap com logo, links de navegação e dropdown do usuário
- **Flash Messages:** Alertas de sucesso/erro com auto-dismiss
- **Footer:** Links de navegação, newsletter (mock), redes sociais
- **Loading State:** Spinner em botões durante submissão de formulários

### 7.2 Design System
- **Framework:** Bootstrap 5.3.3
- **Icons:** Bootstrap Icons 1.11.0
- **Cores Primárias:** Azul (`primary`) conforme navbar e botões
- **Responsividade:** Mobile-first com grid do Bootstrap
- **Cards:** Para exibição de contatos em grid (1/2/3 colunas)

### 7.3 Páginas Principais

#### Home (`static_pages/index.html.erb`)
- Hero section com título e CTA
- 3 cards de features: Seguro, Rápido, Acessível
- CTAs condicionais (cadastro/login ou contatos)

#### Lista de Contatos (`contacts/index.html.erb`)
- Barra de busca com ordenação
- Contador de contatos
- Grid de cards com avatar, nome, telefone
- Ações: Editar e Excluir por contato
- Estado vazio: mensagem motivacional + CTA

#### Formulários
- **Login:** E-mail, senha, checkbox "Lembrar-me" (cookie assinado com expiração de 2 semanas)
- **Cadastro:** Nome, e-mail, senha, confirmação com validações visuais
- **Contato:** Nome e telefone com feedback de erros
- **Recuperar senha:** Etapa 1 (e-mail) e Etapa 2 (nova senha + confirmação) com validações visuais; link "Esqueci minha senha?" na tela de login

---

## 8. Segurança e Autorização

### 8.1 Autenticação
- Customizada sem Devise (has_secure_password + bcrypt)
- Senhas hasheadas com bcrypt
- Session-based (não JWT)
- "Lembrar-me" opcional via `cookies.signed[:user_id]` com expiração de 2 semanas (setado no login e removido no logout)
- Métodos auxiliares em `SessionsHelper`

### 8.2 Autorização
- `before_action :require_logged_in_user` em `ContactsController`
- `before_action :require_admin` para listagem de usuários
- Contatos acessados sempre via `current_user.contacts` (segurança na consulta)
- `set_contact` usa `current_user.contacts.find(params[:id])` (previne acesso a contatos de outros)

### 8.3 Proteções Rails
- CSRF protection habilitado (`csrf_meta_tags`)
- Strong parameters em todos os controllers
- `filter_parameter_logging` para senhas em logs

### 8.4 Rate Limit (anti brute-force)
- Middleware `rack-attack` com throttle de **5 tentativas de login por IP / minuto** (`POST /entrar`)
- Resposta HTTP 429 genérica em pt-BR; janela controlada por `Retry-After: 60`
- Store = `Rails.cache` (por processo em dev/prod — ver débito em §12.4)

---

## 9. Configuração e Deploy

### 9.1 Variáveis de Ambiente (.env)
```
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_PORT=5432
```

### 9.2 Docker (`docker-compose.yml`)
- Serviço `db`: postgres:12.3
- Volume persistente: `postgres`
- Porta: 5432

### 9.3 Comandos Principais
```bash
# Instalar dependências
bundle install

# Configurar banco
rails db:create db:migrate db:seed

# Executar servidor
rails s

# Testes
bundle exec rspec

# Lint
bundle exec rubocop
```

### 9.4 CI — GitHub Actions (`.github/workflows/ci.yml`)

- Triggers: `pull_request` (todas) + `push` em `main` e `develop`
- **Job `lint`:** `ruby/setup-ruby@v1` (lê `.ruby-version`, `bundler-cache: true`) + `bundle exec rubocop`
- **Job `test`:** service container `postgres:12.3` com health check `pg_isready`, envs `POSTGRES_*` (parity com `database.yml`), instala `libpq-dev` + `chromium-driver`, roda `bin/rails db:create db:schema:load` (sem seed — seed colide com `user_spec`) e `bundle exec rspec`

---

## 10. Testes

### 10.1 Cobertura Atual
- **RSpec configurado** (rspec-rails 7.1.1) com shoulda-matchers — **80 exemplos, 0 falhas**
- **Testes de model:**
  - `user_spec.rb` (associações, validações, `admin?`, **digest de recuperação**, **autenticação por token**, **expiração em 2h**)
  - `contact_spec.rb` (validações de telefone, unicidade por usuário, busca)
- **Testes de controller:**
  - `users_controller_spec.rb` (cadastro, autorização de admin)
  - `sessions_controller_spec.rb` (login via session/cookie, erro, logout)
  - `contacts_controller_spec.rb` (CRUD, paginação, busca, isolamento por usuário)
- **Testes de request:** `sessions_spec.rb` (comportamento do cookie "Lembrar-me") + `password_resets_spec.rb` (POST genérico, PATCH válido/confirmação divergente/senha vazia/token inválido/token expirado/e-mail inexistente)
- **Testes de mailer:** `user_mailer_spec.rb` (assunto, destinatário, remetente, nome e link com token no corpo)
- **Testes de feature:** `authentication_spec.rb` e `password_reset_spec.rb` (solicitação, link no e-mail e redefinição com novo login, `rack_test`)
- **Factories:** helpers `create_user`/`create_contact` em `spec/support/factory_helpers.rb`
- **Capybara** configurado em `spec/rails_helper.rb` (`require "capybara/rails"` + `"capybara/rspec"`)
- **Selenium WebDriver** para testes browser (driver `selenium_chrome_headless` para JS, `rack_test` como padrão)

### 10.2 Comandos de Teste
```bash
bundle exec rspec                    # Todos os testes
bundle exec rspec spec/models/       # Testes de modelo
bundle exec rspec spec/controllers/  # Testes de controller
```

---

## 11. Seed de Dados

O arquivo `db/seeds.rb` cria:
- **1 usuário de teste:** `teste@exemplo.com` / senha `123456` (marcado como **admin**: `admin = true`)
- **50 contatos** com nomes e telefones variados para o usuário de teste

---

## 12. Problemas Identificados e Débito Técnico

### 12.1 Inconsistências
- ✅ **Ruby Version:** `.ruby-version` alinhado para 3.3.0 (era 2.7.7 vs Gemfile 3.3.0) — **resolvido em v0.2**
- ✅ **Rails Version:** README atualizado para 7.0.8.6 (citava 7.1.2) — **resolvido em v0.2**
- ✅ **Database:** README atualizado para PostgreSQL (citava SQLite) — **resolvido em v0.2**
- ✅ **Turbo CDN:** Linha CDN `strurbo-rails` removida (Turbo já carregado via importmap) — **resolvido em v0.2**

### 12.2 Funcionalidades Incompletas
1. ✅ **Recuperação de senha:** Implementada em v0.5 (token + digest + e-mail com `letter_opener` em dev, link `/recuperar-senha/edit`, expiração de 2h, mensagens genéricas) — **resolvido em v0.5**
2. **Newsletter:** Formulário no footer é mock (não funcional)
3. **Redes sociais:** Links no footer são `#` (placeholder)

### 12.3 Problemas no Repositório
- ✅ **Arquivo `core`:** Removido do repositório (não mais presente) — **resolvido em v0.2**
- ✅ **Arquivo `views`:** Removido do repositório (saída acidental do `rails generate devise`) — **resolvido em v0.3**
- ✅ **Arquivo `test_hook.rb`:** Removido do repositório (resquício de configuração) — **resolvido em v0.3**
- **Traduções Devise:** `devise.en.yml` existe mas Devise não está em uso

### 12.4 Melhorias Sugeridas
- ✅ Implementar password reset real — **concluído em v0.5**
- ✅ Adicionar paginação na listagem de contatos (Pagy, 12/página) — **concluído em v0.3**
- ✅ Adicionar proteção contra brute-force no login (rack-attack, 5 tentativas/IP/min) — **concluído em v0.6**
- Adicionar campos adicionais (e-mail, endereço) aos contatos
- Implementar busca full-text
- ✅ Adicionar testes model completos — **concluído em v0.3**
- ✅ Corrigir Turbo CDN — **concluído em v0.2** (linha removida, Turbo via importmap)
- ✅ Remover arquivos desnecessários do repositório (`views`, `test_hook.rb`) — **concluído em v0.3**
- Rodar rubocop no código legado (migrations antigas com offenses pré-existentes)
- Rate limit via `:memory_store` é por processo Puma — em deploy multi-worker, migrar para store compartilhado (Redis) na US08

---

## 13. Conclusão

O projeto **Agenda** entrega um sistema funcional de gestão de contatos com:
- ✅ Autenticação completa (cadastro, login, logout)
- ✅ CRUD completo de contatos
- ✅ Interface responsiva com Bootstrap 5
- ✅ Busca e ordenação de contatos
- ✅ Privacidade garantida (usuários veem apenas seus dados)
- ✅ Proteção contra brute-force no login (rate limit rack-attack)
- ✅ Deploy via Docker configurado
- ✅ Estrutura para testes com RSpec

O sistema está funcional para uso básico, com débito técnico documentado para futuras iterações.

---

## 14. Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 0.6 | Ago 2026 | **Rate limit no login**: gem `rack-attack`, middleware + initializer (`config/initializers/rack_attack.rb`, 5 tentativas/IP/min em `POST /entrar`, resposta 429 pt-BR), `Rack::Attack.throttled_responder`, store fresco por exemplo nos specs, **80 exemplos** (request specs: bloqueio 429, liberação da janela, não-afetamento de rotas) |
| 0.5 | Ago 2026 | **Recuperação de senha por e-mail**: rotas `/recuperar-senha*`, `PasswordResetsController`, `UserMailer#password_reset` (assunto pt-BR), views `password_reset.{html,text}` e `password_resets/{new,edit}`, token+digest com expiração de 2h, link "Esqueci minha senha?" no login, `letter_opener` em dev, mensagens genéricas, **77 exemplos** (models, mailers, requests, features) |
| 0.1 | Abr 2026 | Documentação inicial do lançamento |
| 0.2 | Ago 2026 | Alinhamento com o código atual: admin por coluna no banco, "Lembrar-me" funcional, Turbo via importmap, Ruby 3.3.0, Capybara/Selenium configurados, **upgrade rspec-rails 3.9.1 → 7.1.1** (corrige incompatibilidade com Rails 7.0.8), README atualizado |
| 0.4 | Ago 2026 | **CI com GitHub Actions** (`.github/workflows/ci.yml`): jobs `lint` (rubocop) e `test` (rspec com Postgres 12.3 em service container), triggers em PRs e `push` em `main`/`develop` |
| 0.3 | Ago 2026 | Melhorias: **paginação com Pagy** (12/página), **validações de contato** (formato brasileiro de telefone + unicidade por usuário + índices únicos no banco), **"Lembrar-me" com expiração de 2 semanas**, **specs expandidos** (models, controllers, requests, features — 51 exemplos), correção do **label/input do form de login** (ids conflitantes), remoção de arquivos residuais (`views`, `test_hook.rb`) |

---

**Arquivo gerado por:** opencode/big-pickle  
**Atualizado:** 29 de Agosto de 2026

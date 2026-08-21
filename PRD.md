# PRD - Product Requirements Document

## Agenda - Sistema de Gestão de Contatos

**Versão:** 0.2  
**Data:** Agosto 2026  
**Status:** Lançamento Inicial (v0.2 - Alinhamento com o código)

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
| **Testes** | RSpec + Capybara | rspec-rails 7.1.1 |
| **Servidor** | Puma | 5.6.9 |
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
- **Método `sign_in(user)`:** Define session
- **Método `current_user`:** Recupera usuário da session

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
  - **Busca:** Por nome ou telefone (scope `search`)
  - **Ordenação:** Por nome (A-Z) ou data de criação (padrão: nome)
  - Contador de contatos com badge

#### Criação de Contato
- **Rota:** `GET /contacts/new` → `contacts#new`
- **Campos:** Nome, Telefone
- **Validações:**
  - Nome: obrigatório, máximo 50 caracteres
  - Telefone: obrigatório

#### Edição de Contato
- **Rota:** `GET /contacts/:id/edit` → `contacts#edit`
- **Atualização:** `PATCH /contacts/:id` → `contacts#update`

#### Exclusão de Contato
- **Rota:** `DELETE /contacts/:id` → `contacts#destroy`
- **Confirmação:** Via Turbo confirm (`data-turbo-confirm`)

### 4.3 Páginas Estáticas
- **Home:** `GET /` → `static_pages#index` - Apresentação do sistema com features
- **Sobre:** `GET /sobre` → `static_pages#sobre` - Informações sobre o projeto

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

#### Contact (`app/models/contact.rb`)
```ruby
class Contact < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }
  validates :phone, presence: true
  belongs_to :user
  
  scope :search, ->(query) { 
    where("name LIKE :q OR phone LIKE :q", q: "%#{query}%") 
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
- **Login:** E-mail, senha, checkbox "Lembrar-me" (funcional via `cookies.signed.permanent`)
- **Cadastro:** Nome, e-mail, senha, confirmação com validações visuais
- **Contato:** Nome e telefone com feedback de erros

---

## 8. Segurança e Autorização

### 8.1 Autenticação
- Customizada sem Devise (has_secure_password + bcrypt)
- Senhas hasheadas com bcrypt
- Session-based (não JWT)
- "Lembrar-me" opcional via `cookies.signed.permanent[:user_id]` (setado no login e removido no logout)
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

---

## 10. Testes

### 10.1 Cobertura Atual
- **RSpec configurado** (rspec-rails 7.1.1) com shoulda-matchers
- **Testes de model:** `user_spec.rb` (pendente)
- **Testes de controller:**
  - `users_controller_spec.rb`
  - `sessions_controller_spec.rb`
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
1. **Recuperação de senha:** Citada no README mas não implementada (Devise comentado)
2. **Newsletter:** Formulário no footer é mock (não funcional)
3. **Redes sociais:** Links no footer são `#` (placeholder)

### 12.3 Problemas no Repositório
- ✅ **Arquivo `core`:** Removido do repositório (não mais presente) — **resolvido em v0.2**
- **Arquivo `views`:** 1500 bytes no root (saída acidental do `rails generate devise`)
- **Traduções Devise:** `devise.en.yml` existe mas Devise não está em uso

### 12.4 Melhorias Sugeridas
- Implementar password reset real
- Adicionar paginação na listagem de contatos
- Adicionar campos adicionais (e-mail, endereço) aos contatos
- Implementar busca full-text
- Adicionar testes model completos
- ✅ Corrigir Turbo CDN — **concluído em v0.2** (linha removida, Turbo via importmap)
- Remover arquivos desnecessários do repositório

---

## 13. Conclusão

O projeto **Agenda** entrega um sistema funcional de gestão de contatos com:
- ✅ Autenticação completa (cadastro, login, logout)
- ✅ CRUD completo de contatos
- ✅ Interface responsiva com Bootstrap 5
- ✅ Busca e ordenação de contatos
- ✅ Privacidade garantida (usuários veem apenas seus dados)
- ✅ Deploy via Docker configurado
- ✅ Estrutura para testes com RSpec

O sistema está funcional para uso básico, com débito técnico documentado para futuras iterações.

---

## 14. Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 0.1 | Abr 2026 | Documentação inicial do lançamento |
| 0.2 | Ago 2026 | Alinhamento com o código atual: admin por coluna no banco, "Lembrar-me" funcional, Turbo via importmap, Ruby 3.3.0, Capybara/Selenium configurados, **upgrade rspec-rails 3.9.1 → 7.1.1** (corrige incompatibilidade com Rails 7.0.8), README atualizado |

---

**Arquivo gerado por:** opencode/big-pickle  
**Atualizado:** 13 de Agosto de 2026

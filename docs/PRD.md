# PRD - Product Requirements Document

## Agenda - Sistema de Gestão de Contatos

**Versão:** 0.11  
**Data:** Setembro 2026  
**Status:** Em desenvolvimento (v0.10 promovida em `main`; ciclo P2 aberto — v0.12 busca full-text em revisão)

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
- **Campos:** Nome, Telefone, E-mail (opcional), Endereço (opcional), Notas (opcional)
- **Validações:**
  - Nome: obrigatório, máximo 50 caracteres
  - Telefone: obrigatório, formato brasileiro `(XX) XXXXX-XXXX` (com DDD e código de país opcionais), único por usuário
  - E-mail: **opcional**, formato válido e máximo 255 caracteres (quando preenchido)
  - Endereço: opcional, máximo 255 caracteres
  - Notas: opcional, máximo 1000 caracteres (tipo `text`)
  - Índice único em `(user_id, phone)` e em `users.email` no banco de dados

#### Detalhes de Contato
- **Rota:** `GET /contacts/:id` → `contacts#show`
- Exibe Nome, Telefone, E-mail, Endereço e Notas (campos vazios são ocultados)
- Acesso restrito ao dono do contato

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

### 4.6 Exportação de Contatos (CSV) 📤 (US06 — PR-A)

- **Rota:** `GET /contacts/exportar` → `contacts#export` (`on: :collection`, helper `exportar_contacts_path`)
- **Serviço:** `ContactsCsvExporter` (`app/services/contacts_csv_exporter.rb`) — PORO sem ActiveModel, recebe a relação de contatos e devolve a String do arquivo. Isolar a geração permite testá-la sem HTTP e fixa o **contrato de cabeçalho** que o import (PR-B) vai espelhar
- **Colunas:** `nome,telefone,e-mail,endereço,notas` — os 5 campos do contato (US04), na ordem do model
- **Escopo:** `current_user.contacts.order(:name)` — a exportação **ignora a paginação (Pagy) e o filtro `?q=`**, entregando todos os contatos do usuário de uma vez
- **BOM UTF-8:** prefixo `\xEF\xBB\xBF` no arquivo, sem o qual o Excel abre os acentos quebrados
- **Resposta:** `send_data` com `type: "text/csv; charset=utf-8"` e `Content-Disposition: attachment` nomeado `contatos-AAAAMM-DD.csv`
- **Gerado sob demanda:** o arquivo **nunca é gravado no servidor** (RN05) — só existe em memória durante a resposta
- **Autorização:** coberta pelo `before_action :require_logged_in_user` já existente; sem sessão, redireciona para `/entrar` (Cenário 5)
- **Usuário sem contatos:** responde apenas a linha de cabeçalho, sem erro
- **Escaping:** `CSV.generate` entre aspas automaticamente valores com vírgula, aspas ou quebra de linha (o campo `notes` aceita quebra de linha) — o round-trip do PR-B depende disso
- **Fora de escopo (v1):** vCard (`.vcf`), PDF, sincronização com Google Sheets. A **importação** é o PR-B da US06 (§4.7)

### 4.7 Importação de Contatos (CSV) 📥 (US06 — PR-B)

Fecha a US06 e completa o par bidirecional do §4.6: o usuário exporta, sai da plataforma e traz de volta.

- **Rota:** `POST /contacts/importar` → `contacts#import` (`on: :collection`, helper `importar_contacts_path`, `multipart/form-data`, campo `arquivo`)
- **Serviço:** `ContactsCsvImporter` (`app/services/contacts_csv_importer.rb`) — espelha o `ContactsCsvExporter`: recebe `user:` e `file:` e devolve um `Result` (`total`, `imported`, `errors`) ou levanta `InvalidFile` com mensagem já exibível
- **Cabeçalho:** exige as colunas `nome` e `telefone`; `e-mail`, `endereço` e `notas` são opcionais e colunas desconhecidas são ignoradas (compatível com Google Contatos). O cabeçalho é normalizado (minúsculo, sem acento, sem espaço/hífen), então `NOME`, `E-mail` e `email` caem na mesma coluna
- **Validação linha a linha:** cada linha vira `current_user.contacts.build(...)` e é salva pelo **próprio model** — o import não duplica regra de negócio, ele reaproveita as validações do `Contact` (telefone, unicidade por usuário, e-mail, tamanhos)
- **Relatório de erros:** `LineError` (linha, campo em pt-BR, mensagem do model) renderizado na listagem como `Linha 4: telefone inválido. Use o formato (XX) XXXXX-XXXX.` A **linha 1 é o cabeçalho**, então o primeiro dado é a linha 2 — o mesmo número que o usuário vê na planilha
- **Linhas válidas não são descartadas por causa das inválidas (RN04):** o `index` volta renderizado com **HTTP 422** (`unprocessable_entity`) e o flash resume `3 de 4 linhas entraram. Veja o que ficou de fora.`
- **Idempotência e segurança (RN01/RN02):** cada linha cria um contato **novo** — nada é sobrescrito ou apagado; telefone repetido (no arquivo ou já cadastrado) é **erro reportado**, nunca sucesso silencioso, porque a unicidade do model é por `user_id`
- **Escopo (RN03):** os contatos nascem em `current_user.contacts`; o mesmo telefone pode existir em contas diferentes
- **Guardrails:** limite de **5 MB** conferido **antes da leitura** (`ContactsCsvImporter::MAX_SIZE`), encoding **UTF-8 obrigatório** (o tempfile chega em binário e é convertido antes do parse, senão o BOM e os acentos quebram), arquivo vazio, CSV malformado, ausência das colunas obrigatórias e "nenhum arquivo escolhido" viram recusa com mensagem clara
- **Injeção de fórmula neutralizada (§12.4):** valor de célula começando com `=`, `+`, `-`, `@`, tab ou CR recebe o prefixo `'` no parse — vetor de entrada do CSV de terceiros. Valor já escapado não recebe um segundo prefixo, preservando o round-trip
- **UI:** card "Importar contatos (CSV)" na listagem com input de arquivo, dica das colunas e do limite, e o alerta de erros logo abaixo
- **Fora de escopo (v1):** vCard (`.vcf`), mapeamento de colunas por tela, escolha de como tratar duplicados (hoje: sempre erro) e importação em lote de arquivos

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
│ password_digest │           │ email           │
│ admin (bool)    │           │ address         │
│ created_at      │           │ notes           │
│ updated_at      │           │ user_id (FK)    │
└─────────────────┘           │ created_at      │
                              │ updated_at      │
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
  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :phone, presence: true,
                    format: { with: PHONE_REGEX, message: "inválido. Use o formato (XX) XXXXX-XXXX." },
                    uniqueness: { scope: :user_id }
  validates :email,
    format: { with: EMAIL_REGEX, allow_blank: true, message: "inválido." },
    length: { maximum: 255, allow_blank: true }
  validates :address, length: { maximum: 255 }
  validates :notes, length: { maximum: 1000 }

  scope :search, ->(query) {
    where("name ILIKE :q OR phone ILIKE :q OR email ILIKE :q", q: "%#{query}%")
  }
end
```
- **Colunas extras** (`email`, `address` string e `notes` text, todas nullable): migration `20260919232741_add_extra_fields_to_contacts`

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
| GET | `/contacts/exportar` | contacts#export | exportar_contacts_path |
| POST | `/contacts/importar` | contacts#import | importar_contacts_path |
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
- **Footer:** Links de navegação (Home, Contatos, Sobre) e de conta (Meus Contatos, Sair) + copyright — renderizado apenas para usuário logado (mesma condição do header)
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
- Placeholder "Buscar por nome, e-mail ou telefone..." e a dica visível de que a busca ignora acentos e cai para o nome mais parecido em caso de erro de digitação (v0.12)
- Estado de busca sem resultado sugere "um trecho menor, sem acento, ou confira a digitação" (v0.12)
- Contador de contatos
- Botão "Exportar (CSV)" (`btn-outline-success`, ícone `bi-download`) ao lado do "Novo Contato" — visível apenas para usuário logado
- Card "Importar contatos (CSV)": input de arquivo (`accept: .csv,text/csv`), dica das colunas e do limite de 5 MB, botão "Importar" — sempre visível (sem JavaScript) para o usuário logado
- Alerta de erros da importação (`alert-danger`) abaixo do card, listando `Linha N: campo mensagem` para cada linha recusada, com a promessa explícita de que nada foi sobrescrito
- Grid de cards com avatar, nome, telefone
- Ações: Editar e Excluir por contato
- Estado vazio: mensagem motivacional + CTA

#### Busca de contatos (`Contact.search`, v0.12)
- Sem gem nova: migration `EnableUnaccentAndPgTrgmOnContacts` habilita as extensions `unaccent` e `pg_trgm`, que já vêm no `postgresql-contrib` da imagem 12.3
- Recorte por `user_id` herdado de `current_user.contacts`; o filtro de texto só enxerga contatos do dono
- Acento nas duas direções: `unaccent(name) ILIKE unaccent(:termo)` e o inverso — "joao" acha "João" e "João" acha "Joao"
- `ILIKE` também cobre `email`; `phone` casa por substring (não é sensible a acento)
- Plano B para erro de digitação: `word_similarity(unaccent(:termo), unaccent(name|email)) >= Contact::FUZZY_THRESHOLD` (0.4)
- Limiar 0.4 vem de medição, não de palpite: match exato 1.0, erro simples 0.60–0.667, plural 0.50. Transposição (`jocao` para "João") fica em 0.333–0.375 e fica de fora — a busca prefere não trazer o contato errado a trazer o errado com confiança alta
- Termo vazio ou só com espaços devolve conjunto vazio, sem varrer a tabela
- **Limite conhecido:** `unaccent()` é `STABLE` no PostgreSQL 12.3, então índice de expressão GIN é impossível (`functions in index expression must be marked IMMUTABLE`). O plano original da issue #30 previa `gin ((unaccent(name)) gin_trgm_ops)` e estava errado. O filtro roda sobre as linhas do usuário, com o índice de `user_id`; aceitável na escala de um app pessoal. Evoluir para busca indexada exigiria coluna desnormalizada mantida por trigger.


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

### 8.5 Risco aceito — stack fora de suporte (decisão de produto, set/2026)

A stack do projeto está **congelada** conforme o `README.md`, que também declara que o Agenda *"foi uma oportunidade para aprender Ruby on Rails e Bootstrap"*. É um projeto **legado/educacional**, não um produto exposto a tráfego não-confiável. O PO decidiu não gastar orçamento de sprint em upgrade de framework.

| Componente | Versão | Situação em set/2026 |
|---|---|---|
| Ruby | 3.3.0 | com suporte |
| **Rails** | **7.0.8.6** | **EOL desde 15/12/2025** (7.0.10 é a última release) — sem correção de segurança |
| Bootstrap | 5.3.3 | com suporte |
| **PostgreSQL** | **12.3** | **EOL desde 14/11/2024** (`docker-compose.yml` e CI) |

**O que isso significa na prática:** vulnerabilities do Rails conhecidas **não recebem correção** neste projeto, e o Postgres não recebe correção de bugs. Aceito porque o Agenda não expõe superfície pública nem processa dados de terceiros — os contatos são privados por usuário e o único vetor de entrada externa é o CSV do próprio dono da conta (sanitizado no parse, §4.7).

**Compromisso:** nenhuma dependência nova pode exigir versão superior à da stack congelada. Isso descartou a gem `pg_search` (a 2.4.0 exige `activerecord >= 8.0`; a 2.3.7 é a última compatível com Rails 7.0) e levou a US07 para `unaccent` + `pg_trgm`, que já vêm no `postgresql-contrib` da imagem 12.3.

**Se a decisão mudar:** a issue #31 sobe para **P0** e o alvo passa a ser **Rails 8.1** (segurança até 10/10/2027) — não 7.1/7.2, que já estão EOL. O escopo real é maior que os 13 SP originalmente estimados: `puma` 5→6, `rspec-rails` 7→8, `rubocop-rails` 2.24→2.30+ e Postgres 12→16 no compose **e** no CI.

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
- **RSpec configurado** (rspec-rails 7.1.1) com shoulda-matchers — **185 exemplos, 0 falhas**
- **Testes de model:**
  - `user_spec.rb` (associações, validações, `admin?`, **digest de recuperação**, **autenticação por token**, **expiração em 2h**)
  - `contact_spec.rb` (validações de telefone, unicidade por usuário, campos extras, busca com acento, erro de digitação, termo vazio, isolamento por usuário, uso do índice de `user_id` no `EXPLAIN`)
- **Testes de controller:**
  - `users_controller_spec.rb` (cadastro, autorização de admin)
  - `sessions_controller_spec.rb` (login via session/cookie, erro, logout)
  - `contacts_controller_spec.rb` (CRUD, `show`, paginação, busca, campos extras, isolamento por usuário)
- **Testes de request:** `sessions_spec.rb` (comportamento do cookie "Lembrar-me") + `password_resets_spec.rb` (POST genérico, PATCH válido/confirmação divergente/senha vazia/token inválido/token expirado/e-mail inexistente) + `rack_attack_spec.rb` (429 na 6ª tentativa, liberação da janela, rotas não afetadas) + `contacts_export_spec.rb` (**export CSV**: redirecionamento sem sessão, content-type, anexo com nome datado, escopo por usuário, ordenação, exportação ignorando a paginação, usuário sem contatos, BOM, acentos) + `contacts_search_spec.rb` (**busca US07**: sem sessão redireciona, acento nas duas direções, erro de digitação, telefone, sem resultado, termo vazio devolvendo a listagem, isolamento por usuário) + `contacts_import_spec.rb` (**import CSV**: ida e volta exportar→importar, relatório linha+campo, preservação de linhas válidas com inválida no meio, RN01/RN02/RN03, guardrails de 5 MB, encoding, colunas obrigatórias)
- **Testes de serviço:** `spec/services/contacts_csv_exporter_spec.rb` (cabeçalho, uma linha por contato, campos opcionais, escaping de vírgula/aspas/quebra de linha, acentos em UTF-8, BOM, separador, ordem preservada) + `spec/services/contacts_csv_importer_spec.rb` (parse normalizado, BOM ignorado, linhas em branco, reaproveita validações do model, duplicidade, acumulado de erros, arquivo só com cabeçalho, **neutralização de injeção de fórmula**)
- **Testes de mailer:** `user_mailer_spec.rb` (assunto, destinatário, remetente, nome e link com token no corpo)
- **Testes de feature:** `authentication_spec.rb`, `contacts_spec.rb` (CRUD completo, campos extras, paginação, **botão de exportação**, **upload de CSV**, **relatório de erros na tela**, recusa de arquivo inválido), `contacts_search_spec.rb` (**busca pela tela**: acento, erro de digitação, mensagem orientando a busca sem acento, contato de outra conta invisível), `password_reset_spec.rb` e `footer_spec.rb` (rodapé sem mocks, logout pelo rodapé) — `rack_test`
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
2. ✅ **Newsletter:** Formulário mock removido do footer (não havia backend nem previsão no roadmap) — **resolvido em v0.8**
3. ✅ **Redes sociais:** Links `#` (placeholder) removidos do footer — **resolvido em v0.8**
4. ✅ **Links "Ajuda"/"Privacidade":** Eram placeholders `#`; removidos do footer (páginas não existem no escopo do produto) — **resolvido em v0.8**

### 12.3 Problemas no Repositório
- ✅ **Arquivo `core`:** Removido do repositório (não mais presente) — **resolvido em v0.2**
- ✅ **Arquivo `views`:** Removido do repositório (saída acidental do `rails generate devise`) — **resolvido em v0.3**
- ✅ **Arquivo `test_hook.rb`:** Removido do repositório (resquício de configuração) — **resolvido em v0.3**
- ✅ **Traduções Devise:** `devise.en.yml` removido (Devise não está no Gemfile e não há uso no app) — **resolvido em v0.8**

### 12.4 Melhorias Sugeridas
- ✅ Implementar password reset real — **concluído em v0.5**
- ✅ Adicionar paginação na listagem de contatos (Pagy, 12/página) — **concluído em v0.3**
- ✅ Adicionar proteção contra brute-force no login (rack-attack, 5 tentativas/IP/min) — **concluído em v0.6**
- ✅ Adicionar campos adicionais (e-mail, endereço e notas) aos contatos — **concluído em v0.7**
- ✅ Exportar contatos em CSV — **concluído em v0.9**
- ✅ Importar contatos em CSV (round-trip, relatório de erros, RN01–RN04) — **concluído em v0.10**
- ✅ Implementar busca full-text — **entregue em v0.12 (US07, #30)**: `unaccent` + `pg_trgm` do próprio Postgres, **sem gem nova** (o `pg_search` foi descartado por incompatibilidade com a stack congelada — ver §8.5). Sem índice de expressão, porque `unaccent()` é `STABLE` no PG 12.3 — ver §7.3
- ✅ Adicionar testes model completos — **concluído em v0.3**
- ✅ Corrigir Turbo CDN — **concluído em v0.2** (linha removida, Turbo via importmap)
- ✅ Remover arquivos desnecessários do repositório (`views`, `test_hook.rb`) — **concluído em v0.3**
- ✅ Rodar rubocop no código legado (migrations antigas com offenses pré-existentes) — **concluído em v0.3/v0.4** (CHORE-04: lint zerado com exclusão cirúrgica de `Rails/BulkChangeTable` em `db/migrate/**/*`)
- ✅ Sanear o legado: remover `devise.en.yml` e os mocks do footer — **concluído em v0.8**
- Rate limit via `:memory_store` é por processo Puma — em deploy multi-worker, migrar para store compartilhado (Redis). **Fora do ciclo:** dependia do upgrade de Rails (issue #31), que saiu da milestone por decisão de stack congelada (§8.5)
- **Injeção de fórmula no CSV:** **resolvida no PR-B da US06 (v0.10)** — o vetor nasce no CSV de terceiros, então a mitigação ficou no parse: `ContactsCsvImporter#sanitize_formula` prefixa `'` em valores iniciados por `= + - @` (e tab/CR), sem prefixar de novo quando o valor já vem escapado (round-trip exportar→importar→exportar preservado)
- **Importação de contatos (CSV):** **concluída no PR-B da US06** (§4.7) — relatório linha+campo, guardrails de tamanho/encoding, RN01–RN04

---

## 13. Conclusão

O projeto **Agenda** entrega um sistema funcional de gestão de contatos com:
- ✅ Autenticação completa (cadastro, login, logout)
- ✅ CRUD completo de contatos
- ✅ Interface responsiva com Bootstrap 5
- ✅ Busca e ordenação de contatos
- ✅ Campos extras no contato (e-mail, endereço e notas)
- ✅ Exportação de contatos em CSV (BOM UTF-8, escopo por usuário, gerado sob demanda)
- ✅ Importação de contatos em CSV (round-trip sem aprisionamento, relatório linha+campo, RN01–RN04, injeção de fórmula neutralizada)
- ✅ Privacidade garantida (usuários veem apenas seus dados)
- ✅ Proteção contra brute-force no login (rate limit rack-attack)
- ⬜ Busca tolerante a acentos e erros de digitação — **planejado para v0.12 (US07, #30)**
- ✅ Deploy via Docker configurado
- ✅ Estrutura para testes com RSpec

O sistema está funcional para uso básico, com débito técnico documentado para futuras iterações.

**Limite conhecido e aceito:** a stack está fora de suporte oficial (Rails 7.0 e PostgreSQL 12.3). O §8.5 registra a decisão, o risco e a condição para revertê-la.

---

## 14. Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 0.12 | Set 2026 | **Busca full-text tolerante a acentos e erro de digitação (US07 — #30)**: migration `20260929110000_enable_unaccent_and_pg_trgm_on_contacts` habilitando `unaccent` e `pg_trgm` (já presentes no `postgresql-contrib` da imagem 12.3, **zero gem nova**); scope `Contact.search` reescrito com acento nas duas direções, `ILIKE` sobre `name`/`email`, substring em `phone` e `word_similarity >= 0.4` como plano B para erro de digitação; termo vazio devolve vazio; isolamento por `user_id` herdado de `current_user.contacts`. UI: placeholder "Buscar por nome, e-mail ou telefone...", dica de tolerância a acento e mensagem de estado vazio orientando a nova digitação. **Correção de plano:** o `gin ((unaccent(name)) gin_trgm_ops)` previsto na issue é impossível — `unaccent()` é `STABLE`, não `IMMUTABLE`, no PostgreSQL 12.3, e a criação do índice é recusada; o recorte por `user_id` é o que segura a consulta, garantido por spec de `EXPLAIN` com `enable_seqscan = off`. **185 exemplos** (de 161), sem regressão. PRD §7.3 e §12.4 atualizadas. |
| 0.11 | Set 2026 | **Higiene do ciclo P2 (CHORE-05, #49)** — mudança só de docs, sem arquivo de runtime: novo **§8.5 Risco aceito — stack fora de suporte**, registrando a decisão de congelar a stack conforme o `README.md` (Rails 7.0.8.6 EOL desde 15/12/2025; PostgreSQL 12.3 EOL desde 14/11/2024) e o motivo — projeto legado/educacional, sem tráfego não-confiável; §12.4 ajustada (busca full-text remanejada para v0.12/US07; débito do `:memory_store` desvinculado da US08); §13 e §14. No GitHub: US08 (#31) saiu da milestone "P2 — Roadmap" com a decisão do PO no corpo da issue, US07 (#30) reescrita para `unaccent` + `pg_trgm` (o `pg_search` foi descartado: 2.4.0 exige `activerecord >= 8.0`, a 2.3.7 é a última compatível com Rails 7.0), US10 (#33) teve o item "decidir o modelo de papel" removido (a flag booleana `admin` já está em produção), AC transversal das #30–#33 corrigida de "~53" para **161 exemplos**, e a issue de métrica de uso do export/import criada (#50). **161 exemplos, sem regressão.** |
| 0.10 | Set 2026 | **Importação de contatos em CSV (US06 — PR-B)**: rota `POST /contacts/importar` com campo `arquivo` (multipart) e serviço `ContactsCsvImporter` — cabeçalho pt-BR normalizado (minúsculo/sem acento/sem hífen, colunas desconhecidas ignoradas), BOM ignorado, linhas em branco puladas, exigência das colunas `nome` e `telefone`; **validação linha a linha reaproveitando as validações do model** (nenhuma regra duplicada) com relatório `Linha N: campo mensagem`; **HTTP 422** com o `index` re-renderizado e o resumo `3 de 4 linhas entraram. Veja o que ficou de fora.`; **RN01–RN04** (nunca sobrescreve/apaga, telefone duplicado é erro reportado, escopo em `current_user.contacts`); guardrails de **5 MB** (checado antes da leitura) e **UTF-8 obrigatório** (tempfile binário convertido antes do parse); **injeção de fórmula neutralizada** (`= + - @ \t \r` recebem prefixo `'`, sem duplicar quando já escapado — dívida que o §12.4 havia delegated ao PR-B); card de upload na listagem + alerta de erros; extração de `load_contacts` no controller para o `index` e o relatório compartilharem a mesma montagem; specs de serviço (32), request (14) e feature, incluindo **round-trip exportar→importar em outra conta**, **161 exemplos** (de 112). PRD §4.7, §6, §7.3, §10.1, §12.4 e §13 atualizados. US06 concluída. |
| 0.9 | Set 2026 | **Exportação de contatos em CSV (US06 — PR-A)**: serviço `ContactsCsvExporter` (`app/services/contacts_csv_exporter.rb`, primeiro diretório de services do projeto) com o contrato de cabeçalho `nome,telefone,e-mail,endereço,notas`, BOM UTF-8 para o Excel, escaping automático de vírgula/aspas/quebra de linha; rota `GET /contacts/exportar` (`contacts#export`, `on: :collection`) servindo `send_data` como anexo `contatos-AAAAMM-DD.csv`; escopo por usuário via `current_user.contacts.order(:name)` **ignorando paginação e filtro de busca**; botão "Exportar (CSV)" na listagem; specs de serviço, request e feature, **112 exemplos** (de 93). PRD §4.6, §6, §7.3, §10.1, §12.4 e §13 atualizados. A importação é o PR-B da US06. |
| 0.8 | Set 2026 | **Saneamento do legado (US05)**: remoção de `config/locales/devise.en.yml` (Devise fora do Gemfile e sem uso), footer enxuto (removidos o formulário mock de newsletter, os 3 ícones de redes sociais com `href="#"`, os links "Ajuda"/"Privacidade" e o bloco `<% else %>` inalcançável — o footer só é renderizado para usuário logado; colunas rebalanceadas para `col-6 col-md-6` e barra inferior simplificada para copyright), spec de feature do rodapé (`spec/features/footer_spec.rb`) garantindo ausência de `a[href="#"]` e de mocks, **93 exemplos**. PRD §7.1, §10.1, §12.2, §12.3, §12.4 atualizados. |
| 0.7 | Set 2026 | **Campos extras no contato**: migration aditiva e reversível `email`/`address`/`notes` (nullable) em `contacts`, validações de formato (e-mail) e tamanho, e-mail incluído no scope de busca, strong params atualizados, view `show` de contato e parcial `_form` compartilhado, locals pt-BR atualizados, **91 exemplos** (model, controller, feature). PRD §4.2, §5.1, §5.2 atualizados. |
| 0.6 | Ago 2026 | **Rate limit no login**: gem `rack-attack`, middleware + initializer (`config/initializers/rack_attack.rb`, 5 tentativas/IP/min em `POST /entrar`, resposta 429 pt-BR), `Rack::Attack.throttled_responder`, store fresco por exemplo nos specs, **80 exemplos** (request specs: bloqueio 429, liberação da janela, não-afetamento de rotas) |
| 0.5 | Ago 2026 | **Recuperação de senha por e-mail**: rotas `/recuperar-senha*`, `PasswordResetsController`, `UserMailer#password_reset` (assunto pt-BR), views `password_reset.{html,text}` e `password_resets/{new,edit}`, token+digest com expiração de 2h, link "Esqueci minha senha?" no login, `letter_opener` em dev, mensagens genéricas, **77 exemplos** (models, mailers, requests, features) |
| 0.1 | Abr 2026 | Documentação inicial do lançamento |
| 0.2 | Ago 2026 | Alinhamento com o código atual: admin por coluna no banco, "Lembrar-me" funcional, Turbo via importmap, Ruby 3.3.0, Capybara/Selenium configurados, **upgrade rspec-rails 3.9.1 → 7.1.1** (corrige incompatibilidade com Rails 7.0.8), README atualizado |
| 0.4 | Ago 2026 | **CI com GitHub Actions** (`.github/workflows/ci.yml`): jobs `lint` (rubocop) e `test` (rspec com Postgres 12.3 em service container), triggers em PRs e `push` em `main`/`develop` |
| 0.3 | Ago 2026 | Melhorias: **paginação com Pagy** (12/página), **validações de contato** (formato brasileiro de telefone + unicidade por usuário + índices únicos no banco), **"Lembrar-me" com expiração de 2 semanas**, **specs expandidos** (models, controllers, requests, features — 51 exemplos), correção do **label/input do form de login** (ids conflitantes), remoção de arquivos residuais (`views`, `test_hook.rb`) |

---

**Arquivo gerado por:** opencode/big-pickle  
**Atualizado:** 27 de Setembro de 2026

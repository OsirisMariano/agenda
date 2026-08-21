
![agenda](https://github.com/OML-Inovacoes-Digitais-LTDA/agenda/assets/38112205/bdd78d2b-d368-43b9-9eb0-ac7ff021aead)
# Lista de Contatos
De um up na organização dos seus contatos de forma simples rápida com a Agenda! Este projeto foi uma oportunidade
para aprender Ruby on Rails e Bootstrap.

### Tecnologias necessárias:
- Ruby 3.3.0
- Rails 7.0.8.6
- Bootstrap 5.3.3
- PostgreSQL 12.3 (via Docker)
- Hotwire (Turbo + Stimulus)

### Funcionalidades

- Cadastro e autenticação de usuários
- Login/logout com opção "Lembrar-me"
- Gerenciamento de contatos pessoais (CRUD com busca e ordenação)
- Privacidade: cada usuário vê apenas seus próprios contatos
- Usuário admin pode listar todos os usuários cadastrados

### Para executar o projeto:

#### Opção 1: Docker Compose (recomendada)

~~~bash
docker compose up
~~~

#### Opção 2: Local com PostgreSQL

~~~bash
# Clone em sua máquina
git clone https://github.com/OsirisMariano/agenda
cd agenda

# Instale as dependências
bundle install

# Configure o banco (variáveis em .env)
cp .env_example .env
docker compose up -d db

# Prepare o banco
rails db:create db:migrate db:seed

# Execute a aplicação
rails s
~~~

### Testes e lint

~~~bash
bundle exec rspec    # Testes
bundle exec rubocop  # Lint
~~~

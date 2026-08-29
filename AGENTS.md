# AGENTS.md

## Quick verification

bundle exec rspec        # tests (requires PostgreSQL)
bundle exec rubocop      # lint (inherits rubocop-shopify)

Run lint first, then tests. No separate typecheck step (Ruby).

Important when running specs inside the Docker container: `docker-compose.yml`
pins `RAILS_ENV=development` on the `web` service, so a bare `bundle exec rspec`
in the container boots the app in DEVELOPMENT (random failures: 403 Host
Authorization on `www.example.com`, letter_opener instead of test delivery).
Always run specs in the container with `RAILS_ENV=test` (CI already sets it):

```
docker compose exec web sh -c 'RAILS_ENV=test bundle exec rspec'
docker compose exec web sh -c 'RAILS_ENV=test bin/rails db:create db:schema:load'
```

## Environment prerequisites

PostgreSQL must be running. DB connection uses env vars:
`POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`.

Copy `.env_example` to `.env` for local dev.
`bin/setup` does not exist — manual setup:
```
cp .env_example .env
bundle install
rails db:create db:migrate db:seed
```

## Default locale is pt-BR

`config.i18n.default_locale` is `:pt-BR` (`config/application.rb:15`).
User-facing strings, routes (`/entrar`, `/sair`, `/cadastro`, `/usuarios`),
flash messages, and error messages are in Brazilian Portuguese.
Keep new strings in pt-BR unless explicitly told otherwise.

## Auth: custom, no Devise

Authentication is hand-rolled with `bcrypt` (`has_secure_password`).
Session stored in `session[:user_id]`; "remember me" uses `cookies.signed[:user_id]`
(2-week expiry). See `app/helpers/sessions_helper.rb`.

In controller specs, authenticate by setting `session[:user_id]` directly
(see `spec/controllers/contacts_controller_spec.rb:9`).
Do not use Devise test helpers — Devise is not in the Gemfile.

## Contacts are scoped per user

All contact queries go through `current_user.contacts`.
`set_contact` uses `current_user.contacts.find(params[:id])` — accessing
another user's contact raises `ActiveRecord::RecordNotFound`.

## Test factories

No FactoryBot. Custom helpers in `spec/support/factory_helpers.rb`:
- `create_user(overrides)` — generates unique email via `SecureRandom.hex`
- `create_contact(user, overrides)` — generates random valid phone number

Already included globally via `config.include(FactoryHelpers)`.

## Pagination

Pagy, 12 contacts per page, overflow routes to last page.
Bootstrap pagination helpers via `pagy/extras/bootstrap`.

## RuboCop

Inherits `rubocop-shopify` style. Target Ruby 3.3.0.
Migrations excluded from `Rails/BulkChangeTable`.
`db/seeds.rb` excluded from `Rails/Output`.

## Seed data

`rails db:seed` creates admin user `teste@exemplo.com` / `123456` with
50 sample contacts. Safe to re-run (uses `find_or_create_by!`).

## Phone format

Brazilian format validated by `Contact::PHONE_REGEX`:
`(XX) XXXXX-XXXX` (optional country code prefix).
Messages are in pt-BR.

## Specs

RSpec with `--format documentation`. Feature specs use Capybara with
`rack_test` by default, `selenium_chrome_headless` for JS.
System specs drive headless Chrome at 1400x1400.

Run a single file: `bundle exec rspec spec/models/contact_spec.rb`
Run a single example: `bundle exec rspec spec/models/contact_spec.rb:22`

## Login rate limit (rack-attack)

`config/initializers/rack_attack.rb` throttles `POST /entrar` to 5 attempts per
IP per minute (HTTP 429). Uses `Rails.cache` (`:memory_store` in dev/prod;
`:null_store` in test). Specs in `spec/requests/rack_attack_spec.rb`.

In specs, `spec/rails_helper.rb` swaps `Rack::Attack.cache.store` for a fresh
`MemoryStore` per example so counters never leak between examples.

## Git Flow and issue closing

Workflow: `feature/*` → `develop`; releases promote `develop` → `main` (PR).
GitHub only auto-closes issues when a PR merges into the *default branch*
(`main`). A merge into `develop` with `Closes #X` does NOT close the issue —
close board issues manually at release time (or put `Closes #X` on the release
PR). P0/P1/P2 labels and milestones live on the GitHub board as source of
truth; `docs/backlog.md` mirrors status.

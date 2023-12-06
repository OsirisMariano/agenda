source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.1"

gem "rails", "~> 7.0.5", ">= 7.0.5.1"
gem "sprockets-rails"
gem "sqlite3", "~> 1.4"
gem "puma", "~> 5.0"
gem 'bootstrap', '~> 5.2', '>= 5.2.3'
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false
gem "sassc-rails"
gem 'net-http', require: false
gem 'net-imap', require: false
gem 'net-protocol', require: false
gem 'net-smtp', require: false

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'rspec-rails', '~> 3.4', '>= 3.4.2'
  gem 'capybara'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'rails-controller-testing'
  gem 'rspec-json_expectations'
end

group :development do
  gem "web-console"
end

group :test do
  gem "selenium-webdriver"
  gem "webdrivers"
end

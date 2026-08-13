# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

gem "bcrypt", "~> 3.1.7"
gem "bootsnap", require: false
gem "bootstrap", "~> 5.2", ">= 5.2.3"
gem "importmap-rails"
gem "jbuilder"
gem "logger"
gem "net-http", require: false
gem "net-imap", require: false
gem "net-protocol", require: false
gem "net-smtp", require: false
gem "pagy", "~> 9.0"
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "rails", "~> 7.0.5", ">= 7.0.5.1"
gem "sassc-rails"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
# gem 'devise', '~> 4.9', '>= 4.9.3'
gem "dotenv-rails"
gem 'rubyzip', '~> 2.3.0'


group :development, :test do
  gem "capybara"
  gem "debug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rails-controller-testing"
  gem "rspec-json_expectations"
  gem "rspec-rails", "~> 7.1"
  gem "shoulda-matchers", "~> 5.0"
  gem "rubocop-rails", "~> 2.24", ">= 2.24.1"
  gem "rubocop-shopify", "~> 2.15", ">= 2.15.1"
end

group :development do
  gem "web-console"
end

group :test do
  gem "selenium-webdriver", "~> 4.19"
  # gem 'webdrivers'
end

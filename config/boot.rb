# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "logger" # Fix: define ::Logger before activesupport loads (Rails 7.0.x + logger gem)
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

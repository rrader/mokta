# frozen_string_literal: true

require "byebug"
require "capybara/rspec"
require "sinatra"
require_relative "../app"

Capybara.app = Sinatra::Application
Capybara.app_host = "http://okta.test"

# frozen_string_literal: true

require "byebug"
require "capybara/rspec"
require "sinatra"

Capybara.app = Sinatra::Application
Capybara.app_host = "http://okta.test"

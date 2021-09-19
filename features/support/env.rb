# frozen_string_literal: true

# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

ENV["RAILS_ENV"] ||= 'test'
$LOADING_CUCUMBER_ENV = true
require 'webdrivers'
require 'cucumber/rails'
require 'email_spec/cucumber'
require 'rspec/expectations'
require 'capybara-screenshot/cucumber'
require 'cucumber/rspec/doubles'

Dir[File.expand_path("#{Rails.root}/lib/test/**/*.rb")].each { |f| load f }
require File.expand_path("#{File.dirname(__FILE__)}/../../config/environment")
require "rspec/rails"
require_relative '../../spec/ivl_helper'

# Capybara defaults to CSS3 selectors rather than XPath.
# If you'd prefer to use XPath, just uncomment this line and adjust any
# selectors in your step definitions to use the XPath syntax.
# Capybara.default_selector = :xpath

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  load "#{Rails.root}/db/seedfiles/english_translations_seed.rb"
  DatabaseCleaner.strategy = :truncation, {:except => %w[translations]}
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# You may also want to configure DatabaseCleaner to use different strategies for certain features and scenarios.
# See the DatabaseCleaner documentation for details. Example:
#
#   Before('@no-txn,@selenium,@culerity,@celerity,@javascript') do
#     # { :except => [:widgets] } may not do what you expect here
#     # as Cucumber::Rails::Database.javascript_strategy overrides
#     # this setting.
#     DatabaseCleaner.strategy = :truncation
#   end
#
#   Before('~@no-txn', '~@selenium', '~@culerity', '~@celerity', '~@javascript') do
#     DatabaseCleaner.strategy = :transaction
#   end
#

# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
Cucumber::Rails::Database.javascript_strategy = :truncation

Capybara::Screenshot.webkit_options = { width: 2280, height: 1800 }
Capybara::Screenshot.prune_strategy = :keep_last_run
Webdrivers.cache_time = 86_400

# Selenium::WebDriver::Chrome.path = '/opt/homebrew-cask/Caskroom/google-chrome/latest/Google Chrome.app/Contents/MacOS/Google Chrome'

Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("headless")
  options.add_argument("--window-size=1920,1080")
  options.add_argument("--enable-features=NetworkService,NetworkServiceInProcess")

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.open_timeout = 240 # instead of the default 60
  client.read_timeout = 240 # instead of the default 60

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options,
                                 http_client: client)
end

unless (env_no = ENV['TEST_ENV_NUMBER'].to_i).zero?
  # As described in the readme
  Capybara.server_port = 8888 + env_no
end

Capybara.default_driver = :selenium_chrome
# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 6.1.7.8'
gem 'sidekiq', '~> 6.5.10'
gem 'globalid'
#######################################################
# FIXME
#######################################################

# Update to use features from new version
gem 'effective_datatables', path: './project_gems/effective_datatables-2.6.14'

# Verify this gem git reference is necessary.  Otherwise point it to release level
gem 'prawn', :git => 'https://github.com/prawnpdf/prawn.git', :ref => '8028ca0cd2'

## Fix this dependency -- bring into project
gem 'simple_calendar', :git => 'https://github.com/harshared/simple_calendar.git'

#######################################################

#######################################################
# Local components/engines
#######################################################
gem 'acapi',              git: "https://github.com/ideacrew/acapi.git", branch: 'trunk'
gem 'aca_entities',       git: 'https://github.com/ideacrew/aca_entities.git', branch: 'trunk'
gem 'event_source',       git:  'https://github.com/ideacrew/event_source.git', branch: 'trunk'
gem "benefit_markets",    path: "components/benefit_markets"
gem "benefit_sponsors",   path: "components/benefit_sponsors"
gem 'financial_assistance', path: 'components/financial_assistance'
gem "notifier",           path: "components/notifier"
gem 'openhbx_cv2',        git:  'https://github.com/ideacrew/openhbx_cv2.git', branch: 'trunk'
gem 'resource_registry',  git:  'https://github.com/ideacrew/resource_registry.git', branch: 'trunk'

gem "sponsored_benefits", path: "components/sponsored_benefits"
gem "transport_gateway",  path: "components/transport_gateway"
gem "transport_profiles", path: "components/transport_profiles"
gem 'ui_helpers',         path: "components/ui_helpers"
#######################################################

## MongoDB gem dependencies
gem 'bson',                     '~> 4.3'
gem 'mongoid',                  '~> 7.5.4'
gem 'mongo',                    '~> 2.6'
gem 'mongo_session_store',      '~> 3.1'
gem 'mongoid-autoinc',          '~> 6.0'
gem 'mongoid-history',          '~> 0.8'
gem 'mongoid_userstamp',        '~> 0.4', :path => './project_gems/mongoid_userstamp-0.4.0'
gem 'mongoid_rails_migrations', '~> 1.2'

## General gems
gem 'aasm',                     '~> 4.8'
gem 'recurring_select'

gem 'aws-sdk',                  '~> 3.2'
gem 'bcrypt',                   '~> 3.1'
gem 'bootsnap',                 '>= 1.1', require: false
gem 'browser',                  '2.7.0'
gem 'ckeditor',                 '~> 4.2.4'
gem 'coffee-rails',             '~> 5.0.0'
gem 'combine_pdf',              '~> 1.0'
gem 'config',                   '~> 2.0'
gem 'devise',                   '~> 4.5'
gem 'devise-jwt',               '0.9.0'
gem 'warden-jwt_auth',          '0.6.0'
gem 'jwt', "~> 2.2.1"
gem 'haml',                     '~> 5.0'
gem 'httparty',                 '~> 0.21'
gem 'i18n',                     '~> 1.5'
gem 'i18n-tasks', '~> 0.9.33'
gem 'interactor',               '~> 3.0'
gem 'interactor-rails',         '~> 2.2'
gem 'jbuilder',                 '~> 2.7'
gem 'jquery-rails',             '~> 4.4'
gem 'jquery-ui-rails',          '>= 7.0.0'
gem 'kaminari',                 '= 1.2.1'
gem 'kaminari-mongoid'
gem 'kaminari-actionview'
gem 'language_list',            '~> 1'
gem 'mail',                     '~> 2.7'
gem 'maskedinput-rails',        '~> 1.4'
gem 'money-rails',              '~> 1.13'
gem 'net-ssh',                  '= 4.2.0'
gem 'nokogiri'
gem 'nokogiri-happymapper',     '~> 0.8.0', :require => 'happymapper'
gem 'non-stupid-digest-assets'
gem 'pundit',                   '~> 2.0'
gem "recaptcha",                '~> 4.13', require: 'recaptcha/rails'
gem 'redis',                    '~> 4.0'
gem 'redis-rails',              '~> 5.0.2'
gem 'redis-store',              '~> 1.10'
gem 'rexml',                    '>= 3.3.3'
gem 'resque',                   '~> 2.6.0'
gem 'roo',                      '~> 2.10'
gem 'rubyzip', '>= 1.3.0'
gem 'ruby-saml',                '~> 1.3'
gem 'sassc',                    '~> 2.0'
gem 'sass-rails',               '~> 5'
gem 'slim',                     '~> 3.0'
gem 'slim-rails',               '~> 3.2'
gem 'symmetric-encryption',     '3.9.1'
gem 'turbolinks',               '~> 5'
gem 'uglifier',                 '>= 4'
gem 'virtus',                   '~> 1.0'
gem 'wicked_pdf',               '~> 1.1.0'
gem 'wkhtmltopdf-binary-edge',  '~> 0.12.3.0'
gem 'webpacker',                '~> 4.0.2'
gem 'fast_jsonapi'
gem 'loofah', '~> 2.19.1'
gem 'stimulus_reflex', '3.4.2'
gem 'rack-cors'
gem 'holidays', '~> 8.6'

gem 'dry-configurable', '0.13.0'
gem 'dry-container', '0.9.0'
gem 'devise-security'
gem 'file_validators'

group :development do
  gem "certified",              '~> 1'
  gem 'overcommit',             '~> 0.47'
  gem 'rubocop',                require: false
  gem 'rubocop-rspec'
  gem 'rubocop-git'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console',            '>= 3'
  gem 'listen',                 '~> 3.3.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'action-cable-testing'
  gem 'addressable',            '~> 2.3'
  gem 'axe-core-cucumber',      '~> 4.8.0'
  gem 'brakeman',               '~> 6.1'
  gem 'climate_control',        '~> 0.2.0'
  gem 'email_spec',             '~> 2'
  gem 'factory_bot_rails',      '~> 4.11'
  gem 'ffaker'
  gem 'forgery',                '~> 0.7.0'
  gem 'parallel_tests',         '~> 2.26.2'
  gem 'rails-controller-testing'
  gem 'railroady',              '~> 1.5.3'
  gem 'rdoc',                   '~> 6.3.4'
  gem 'rspec-rails',            '~> 5.0.1'
  gem 'rspec_junit_formatter'
  gem 'sdoc',                    '~> 1.0'
  gem 'stimulus_reflex_testing', '~> 0.3.0'
  gem 'yard',                    '>= 0.9.36',  require: false
  gem 'yard-mongoid',           '~> 0.1',     require: false
end

group :test do
  gem 'action_mailer_cache_delivery', '~> 0.3'
  gem 'capybara',                     '~> 3.12'
  gem 'capybara-screenshot',          '~> 1.0.18'
  gem 'cucumber-rails',               '2.0', :require => false

  ## Verify Rails 5 eliminates need for this gem with MongoDB
  gem 'database_cleaner-mongoid',     '~> 2.0', '>= 2.0.1'
  gem 'fakeredis',                    '~> 0.7.0', :require => 'fakeredis/rspec'
  gem 'mongoid-rspec',                '~> 4'
  gem 'rspec-instafail',              '~> 1'
  gem 'rspec-benchmark'
  gem 'ruby-progressbar',             '~> 1'
  gem 'shoulda-matchers',             '~> 3'
  gem 'simplecov',                    '~> 0.22.0',  :require => false
  gem 'simplecov-cobertura'
  gem 'test-prof',                    '~> 1.3'
  gem 'warden',                       '~> 1.2.7'
  gem 'watir',                        '~> 6.18.0'
  gem 'webdrivers', '~> 5.3.1'
  gem 'webmock',                      '~> 3.0.1'
end

group :production do
  gem 'newrelic_rpm', '~> 9.6'
  gem 'unicorn',      '~> 4.8'
  gem 'puma',         '~> 5.6', '>= 5.6.8'
end

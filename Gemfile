source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'
gem 'rails', '~> 5.2.2'

#######################################################
# FIXME
#######################################################

# Update to use features from new version
# gem 'effective_datatables', path: './project_gems/effective_datatables-2.6.14'
gem 'effective_datatables', '~> 4.3.18'

# Verify this gem git reference is necessary
gem 'prawn', :git => 'https://github.com/prawnpdf/prawn.git', :ref => '8028ca0cd2'

## Fix this dependency -- bring into project
# gem 'recurring_select', :git => 'https://github.com/brianweiner/recurring_select'

## Fix this dependency -- bring into project
# gem 'simple_calendar', :git => 'https://github.com/harshared/simple_calendar'

## Remove this component and code in directory tree ##
# gem "sponsored_benefits", path: "components/sponsored_benefits"

#######################################################

#######################################################
# Local components/engines
#######################################################
# gem 'acapi',              git: "https://github.com/dchbx/acapi.git", branch: 'development'
# gem "benefit_markets",    path: "components/benefit_markets"
# gem "benefit_sponsors",   path: "components/benefit_sponsors"
# gem 'openhbx_cv2',        git: 'https://github.com/dchbx/openhbx_cv2.git', branch: 'master'
# gem "notifier",           path: "components/notifier"
# gem "transport_gateway",  path: "components/transport_gateway"
# gem "transport_profiles", path: "components/transport_profiles"
#######################################################

## MongoDB gem dependencies
gem 'bson',                 '~> 4.3.0'
gem 'carrierwave-mongoid',  '~> 1.2.0',  :require => 'carrierwave/mongoid'
gem 'money-rails',          '~> 1.13.0'
gem 'mongoid',              '~> 7.0'
gem 'mongo',                '~> 2.6.2'
gem 'mongo_session_store',  '~> 3.1.0'
gem 'mongoid-autoinc',      '~> 6.0.3'
gem 'mongoid-history',      '~> 0.8.1'
gem 'mongoid-versioning',   '~> 0.1.0'
gem 'mongoid_userstamp',    '~> 0.4.0'
gem 'mongoid_rails_migrations', '~> 1.2.0'

## General gems
gem 'aasm',             '~> 4.8.0'
gem 'addressable',      '~> 2.3.8'
gem 'animate-rails',    '~> 1.0.10'
gem 'aws-sdk',          '~> 2.2.37'
gem 'bcrypt',           '~> 3.1'
gem 'bootsnap',         '>= 1.1.0', require: false

gem 'bootstrap',        '~> 4.1.3'
# gem 'bootstrap-multiselect-rails', '~> 0.9.9'
# gem 'bootstrap-multiselect-rails'
# gem 'bootstrap-slider-rails', '6.0.17'
# gem 'bootstrap-slider-rails'
# gem 'less-rails-bootstrap', '~> 3.3.1.0'
# gem 'less-rails-bootstrap'

gem 'maskedinput-rails',  '~> 1.4.1'

gem 'ckeditor',         '~> 4.2.4'
gem 'coffee-rails',     '~> 4.2.2'
gem 'combine_pdf',      '~> 1.0.9'
gem 'config',           '~> 1.0.0'
gem 'curl',             '~> 0.0.9'

# gem 'devise', '>= 3.5.4'
# gem 'devise'

gem 'haml',             '~> 5.0.4'

# gem 'highcharts-rails', '~> 4.1', '>= 4.1.9'

gem 'httparty',         '~> 0.16.2'
gem 'i18n',             '~> 1.5.1'
gem 'interactor',       '~> 3.1.0'
gem 'interactor-rails', '~> 2.2.0'
gem 'jbuilder',         '~> 2.7.0'

# gem 'jquery-datatables-rails', '3.4.0'
# gem 'jquery-datatables-rails'

# gem 'jquery-rails', '4.0.5'
# gem 'jquery-rails'
# gem 'jquery-turbolinks'
# gem 'jquery-ui-rails'

gem 'kaminari',             '~> 0.17.0'
gem 'language_list',        '~> 1.1.0'


# gem 'mail', '2.6.3'



gem 'nokogiri',             '~> 1.10.0'
gem 'nokogiri-happymapper', '~> 0.8.0', :require => 'happymapper'
gem 'pundit', '~> 2.0'


# gem 'redcarpet', '3.4.0'
gem "recaptcha",    '~> 4.13.1', require: 'recaptcha/rails'
gem 'redcarpet',    '~> 3.4.0'

gem 'redis', '~> 4.0'
gem 'resque',       '~> 2.0.0'
gem 'roo', '~> 2.1.0'
gem 'ruby-saml', '~> 1.3.1'

## Deprecated
##
gem 'sassc', '~> 1.12'

gem 'slim', '~> 3.0.9'
# gem 'slim-rails'

# gem 'sprockets', '~> 2.12.3'

gem 'symmetric-encryption', '~> 3.6.0'
gem 'therubyracer', '~> 0.12.3', platforms: :ruby


gem 'turbolinks', '~> 5'


gem 'virtus', '~> 1.0.5'
gem 'wicked_pdf', '1.0.6'
gem 'wkhtmltopdf-binary-edge', '~> 0.12.3.0'

gem 'webpacker', '~> 3.4.3'

#######################################################
# Removed gems
#######################################################
#
# gem 'acapi', path: '../acapi'
# gem 'bh'
# gem 'devise_ldap_authenticatable', '~> 0.8.1'
# gem 'highcharts-rails', '~> 4.1', '>= 4.1.9'
# gem 'kaminari-mongoid' #DEPRECATION WARNING: Kaminari Mongoid support has been extracted to a separate gem, and will be removed in the next 1.0 release.
# gem 'mongoid-encrypted-fields', '~> 1.3.3'
# gem 'mongoid-history', '~> 5.1.0'
# gem 'rypt', '0.2.0'
# gem 'rocketjob_mission_control', '~> 3.0'
# gem 'rails_semantic_logger'
# gem 'rocketjob', '~> 3.0'
#
#######################################################

group :doc do
  gem 'sdoc', '~> 1.0'
end

group :development do
  gem "certified"
  gem 'overcommit', '0.47'
  gem 'rubocop', require: false
  # gem 'web-console', '2.3.0'

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.6.3'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :development, :test do
  gem 'capistrano', '3.3.5'
  gem 'capistrano-rails', '1.1.6'

  # gem 'email_spec', '2.0.0'
  # gem 'email_spec'

  # gem 'factory_girl_rails', '4.6.0'
  # gem 'factory_bot_rails'

  gem 'forgery', '~> 0.7.0'

  gem 'parallel_tests', '2.26.2'
  gem 'puma', '~> 3.11'
  # gem 'railroady', '~> 1.5.2'
  gem 'railroady', '~> 1.5.3'

  # gem 'rspec-rails', '~> 3.4.2'
  # gem 'rspec-rails', '~> 3.8'

  # gem 'rspec_junit_formatter', '0.2.3'
  # gem 'spring', '1.6.3'

  gem 'yard', '~> 0.9.12', require: false

  # gem 'yard-mongoid', '~> 0.1.0', require: false
  # gem 'yard-mongoid'
end

group :test do
  # gem 'action_mailer_cache_delivery', '~> 0.3.7'
  gem 'capybara', '2.6.2'
  gem 'capybara-screenshot', '1.0.18'
  # gem 'cucumber', '2.3.3'
  # gem 'cucumber-rails', '1.4.3', :require => false
  # gem 'database_cleaner', '1.5.3'

  # gem 'action_mailer_cache_delivery'

  gem 'cucumber'
  # gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'fakeredis', '~> 0.7.0', :require => 'fakeredis/rspec'

  # gem 'mongoid-rspec', '3.0.0'
  # gem 'mongoid-rspec'

  gem 'poltergeist', '~> 1.17.0'

  # gem 'rspec-instafail'

  # gem 'ruby-progressbar', '1.6.0'
  gem 'shoulda-matchers', '3.1.1'
  gem 'simplecov', '0.14.1', :require => false
  gem 'test-prof', '0.5.0'

  gem 'ruby-progressbar'

  gem 'warden', '~> 1.2.7'
  gem 'watir', '~> 6.10.3'
  gem 'webmock', '~> 3.0.1'
end

group :production do
  gem 'eye', '0.8.0'
  gem 'newrelic_rpm', '~> 5.0.0'
  gem 'unicorn', '~> 4.8.3'
end

#######################################################
## Rails 5 Migration
#######################################################

#######################################################
# Upgraded gems
#######################################################
# gem 'aws-sdk',        '~> 2.2.4'
# gem 'coffee-rails', '~> 4.1.0'
# gem 'rails-i18n', '4.0.8'
# gem 'jbuilder', '~> 2.0'
# gem 'mongoid', '~> 5.4.0'
# gem 'mongoid-enum'
# gem 'mongoid_rails_migrations', git: 'https://github.com/adacosta/mongoid_rails_migrations.git', branch: 'master'
# gem 'nokogiri', '1.6.7.2'
# gem 'pundit', '~> 1.0.1'
# gem 'rails', '4.2.7.1'
# gem "recaptcha", '4.3.1', require: 'recaptcha/rails'
# gem 'sdoc', '~> 0.4.0'
# gem 'turbolinks', '2.5.3'
# gem 'effective_datatables', '~> 2.6.14'
#######################################################

#######################################################
# Removed gems
#######################################################
# gem 'chosen-rails'
# gem 'non-stupid-digest-assets', '~> 1.0', '>= 1.0.9'
# gem 'redis-rails',  '~> 5.0.2'
# gem 'sass-rails', '~> 5.0'
# gem 'uglifier', '>= 1.3.0', require: 'uglifier'
#######################################################

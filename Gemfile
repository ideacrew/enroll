source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'

# Use SCSS for stylesheets
# gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'animate-rails', '~> 1.0.7'
gem 'maskedinput-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'jquery-turbolinks'
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'less-rails-bootstrap', '~> 3.3.1.0'
gem 'font-awesome-rails'
gem 'nokogiri-happymapper', :require => 'happymapper'

gem 'mongoid', '~> 4.0.2'
gem 'origin', '~> 2.1.1'
gem 'moped', '~> 2.0.4'
gem 'carrierwave-mongoid', '0.7.1', :require => 'carrierwave/mongoid'
gem "mongoid_auto_increment"
# gem 'mongoid-autoinc'
gem 'mongoid-versioning'

gem 'money-rails', '~> 1.3.0'
gem "mongoid-enum", '~> 0.2.0'
gem 'mongo_session_store-rails4', '~> 6.0.0'

## Add field-level encryption
# gem 'mongoid-encrypted-fields', '~> 1.3.3'
gem 'symmetric-encryption', '~> 3.6.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'acapi', git: "git://github.com/dchbx/acapi.git", branch: 'development'
# gem 'acapi', path: "../acapi"

gem 'aasm', '~> 4.0.7'
gem 'haml'
# gem 'bh'

gem 'devise', '~> 3.4.1'
# gem 'devise_ldap_authenticatable', '~> 0.8.1'
gem 'cancancan', '~> 1.9.2'

# will provide fast group premium plan fetch
gem 'redis-rails'

gem 'kaminari'

gem 'sprockets' , "~> 2.12.3"
# for I18n
gem 'rails-i18n', '~> 4.0.0'
gem 'mail'
gem 'bson', '2.3.0'
# gem 'rypt', '0.2.0'

gem 'language_list', '~> 1.1.0'
gem 'bootstrap-multiselect-rails', '~> 0.9.9'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'pry-remote'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Use Capistrano for deployment
  gem 'capistrano', '3.3.5'
  # gem 'capistrano-scm-gitcopy'
  gem 'capistrano-rails', '~> 1.1.2'
  gem 'ruby-progressbar', '1.6.0'

  # Keep these in Development and Test environments for access by rails generators
  gem 'rspec-rails', '~> 3.1.0'
  gem 'factory_girl_rails', "~> 4.0"
  gem 'forgery'
end

group :test do
  gem 'mongoid-rspec'
  gem 'watir'
  gem 'cucumber-rails', '~> 1.4.2', :require => false
  gem 'database_cleaner', '1.3.0'
  gem 'shoulda-matchers', require: false
  gem 'email_spec'
  gem 'action_mailer_cache_delivery', '~> 0.3.7'
#  gem 'headless'
end

group :production do
  # Use Unicorn as the app server
  gem 'unicorn', '~> 4.8.3'
  gem 'eye'
end

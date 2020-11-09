# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'mongoid-rspec'
require 'shoulda/matchers'
require 'database_cleaner'
require 'capybara/rails'
require 'capybara/rspec'
require 'factory_bot_rails'
require 'test_prof'
require 'test_prof/recipes/rspec/factory_default'

FactoryBot.definition_file_paths = [
  "spec/dummy/spec/factories"
  #File.expand_path(File.join(File.dirname(__FILE__),'spec/dummy/spec/factories'))
]
puts FactoryBot.definition_file_paths.inspect
FactoryBot.find_definitions

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
  end
end
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  DatabaseCleaner.strategy = :truncation
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
#  config.include ModelMatcherHelpers, :type => :model
  config.include Mongoid::Matchers, type: :model
  config.include Devise::Test::ControllerHelpers, :type => :controller
  config.include Devise::Test::ControllerHelpers, :type => :view
  config.include FactoryBot::Syntax::Methods
  config.include Capybara::DSL

  config.after(:example, :dbclean => :after_each) do
    DatabaseCleaner.clean
  end

  config.around(:example, :dbclean => :around_each) do |example|
    DatabaseCleaner.clean
    example.run
    DatabaseCleaner.clean
  end
end

def main_app
  Rails.application.class.routes.url_helpers
end
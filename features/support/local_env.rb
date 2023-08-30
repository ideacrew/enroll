# Enable Factory_bot
World(FactoryBot::Syntax::Methods)
if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.command_name "cukes_#{Process.pid}_#{ENV['TEST_ENV_NUMBER'] || '1'}"
  SimpleCov.start 'rails'
end
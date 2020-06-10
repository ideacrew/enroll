$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "benefit_markets/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "benefit_markets"
  s.version     = BenefitMarkets::VERSION
  s.authors     = ["IdeaCrew"]
  s.email       = ["enroll_app@ideacrew.com"]
  s.homepage    = "https://github.com/dchbx"
  s.summary     = "Create and manage markets that enable benefit sponsors to access products and offer benefits to their members."
  s.description = "Create and manage markets that enable benefit sponsors to access products and offer benefits to their members."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails",                     "~> 5.2.3"

  s.add_dependency "mongoid",                   "~> 7.0.2"

  s.add_dependency "aasm",                      "~> 4.8"
  s.add_dependency 'active_model_serializers',  '~> 0.10'
  s.add_dependency 'config',                    '~> 2.0'
  s.add_dependency 'language_list',             '~> 1'
  s.add_dependency 'money-rails',               '~> 1.13'
  s.add_dependency 'pundit',                    '~> 2.0'
  s.add_dependency 'virtus',                    '~> 1.0'
  s.add_dependency "slim",                      "~> 3.0"
  s.add_dependency 'symmetric-encryption',      '~> 3.9.1'

  s.add_dependency 'dry-types'
  s.add_dependency 'dry-validation'
  s.add_dependency 'dry-struct'
  s.add_dependency 'dry-monads'


  # s.add_development_dependency 'bundler-audit',             '~> 0.6'
  s.add_development_dependency 'capybara',                  '~> 3.12'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot_rails',         '~> 4'
  s.add_development_dependency 'forgery',                   '~> 0.7.0'
  s.add_development_dependency 'mongoid_rails_migrations',  '~> 1.2.0'
  s.add_development_dependency "mongoid-rspec",             '~> 4'
  s.add_development_dependency 'rails-perftest',            '~> 0.0.7'
  s.add_development_dependency "rspec-rails",               '~> 3.8'
  s.add_development_dependency 'rubocop-rspec',             '~> 1.31'
  s.add_development_dependency 'shoulda-matchers',          '~> 3'
  s.add_development_dependency 'test-prof',                 '~> 0.5.0'

end


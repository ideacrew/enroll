$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "transport_profiles/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "transport_profiles"
  s.version     = TransportProfiles::VERSION
  s.authors     = ["Trey Evans"]
  s.email       = ["lewis.r.evans@gmail.com"]
  s.homepage    = "https://github.com/ideacrew"
  s.summary     = "Transport gateway credentials and providers"
  s.description = "Transport gateway credentials and providers"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 5.2.4.3"
  s.add_dependency 'mongoid', "~> 7.0.2"
  s.add_dependency 'transport_gateway'
  s.add_dependency 'symmetric-encryption'
  s.add_dependency 'rubyzip', '>= 1.3.0'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'rspec'
end

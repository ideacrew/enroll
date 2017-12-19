$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "reports/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "reports"
  s.version     = Reports::VERSION
  s.authors     = ["Raghuram"]
  s.email       = ["raghuramg83@gmail.com"]
  s.homepage    = "https://github.com/dchbx"
  s.summary     = %q{Engine for generating H36 and H41 xmls}
  s.description = %q{Includes generators for schema valid IRS H36/H41 xmls}
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.2.7.1" 
  s.add_dependency "slim", "3.0.8" 
  s.add_dependency "mongoid", "~> 5.0.1"
  s.add_dependency 'acapi'

  s.add_development_dependency "rspec-rails" 
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
end

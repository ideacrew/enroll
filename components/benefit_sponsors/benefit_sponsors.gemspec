$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "benefit_sponsors/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "benefit_sponsors"
  s.version     = BenefitSponsors::VERSION
  s.authors     = ["Brian Weiner"]
  s.email       = ["brian.weiner@dc.gov"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of BenefitSponsors."
  s.description = "TODO: Description of BenefitSponsors."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.7.1"

  s.add_development_dependency "sqlite3"
end

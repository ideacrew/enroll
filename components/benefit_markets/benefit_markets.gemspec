$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "benefit_markets/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "benefit_markets"
  s.version     = BenefitMarkets::VERSION
  s.authors     = ["Brian Weiner"]
  s.email       = ["brian.weiner@dc.gov"]
  s.homepage    = "https://github.com/dchbx/enroll"
  s.summary     = "BenefitMarkets are how Exchanges define sets of related plans to be made available for shopping"
  s.description = "For SHOP, IVL, or other market types"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.7.1"

  s.add_development_dependency "sqlite3"
end

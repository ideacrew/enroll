$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "notifier/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "notifier"
  s.version     = Notifier::VERSION
  s.authors     = ["Dan Thomas"]
  s.email       = ["dan@ideacrew.com"]
  s.homepage    = "https://github.com/ideacrew"
  s.summary     = %q{An engine for generating notices by merging data with template text}
  s.description = %q{Using a class instance and reference to a pre-defined template, build a customized notice in PDF format \
                      and drop at well-known endpoint }
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 5.2.4.3"
  s.add_dependency "slim", "3.0.9"
  s.add_dependency "mongoid", "~> 7.0.2"
  s.add_dependency "virtus", "~> 1.0.5"
  s.add_dependency "redcarpet", "~> 3.4.0"
  s.add_dependency "wkhtmltopdf-binary-edge", "~> 0.12.3.0"
  s.add_dependency "wicked_pdf", "1.1.0"
  s.add_dependency "combine_pdf"
  s.add_dependency "ckeditor", '4.2.4'
  s.add_dependency "non-stupid-digest-assets"
  s.add_dependency "roo", "~> 2.1.0"
  s.add_dependency 'aasm', '~> 4.8'
  s.add_dependency 'config'
  s.add_dependency 'money-rails', '~> 1.13'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_bot_rails'

end

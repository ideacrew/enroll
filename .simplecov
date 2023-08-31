require 'simplecov'
require 'simplecov-cobertura'

# .simplecov
if ENV["COVERAGE"]
  SimpleCov.start 'rails' do
    # any custom configs like groups and filters can be here at a central place
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
    enable_coverage :branch
  end
end

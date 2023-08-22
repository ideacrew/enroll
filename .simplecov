require 'simplecov'
require 'simplecov-cobertura'

# .simplecov
SimpleCov.start 'rails' do
  # any custom configs like groups and filters can be here at a central place
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

end

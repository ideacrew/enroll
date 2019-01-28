module ModelMatcherHelpers
  RSpec::Matchers.define :have_errors_on do |attribute|
     match do |model|
     	model.errors.include?(attribute.to_sym)
     end
  end

end

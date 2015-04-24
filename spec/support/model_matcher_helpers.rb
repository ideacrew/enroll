module ModelMatcherHelpers
  RSpec::Matchers.define :have_errors_on do |prop|
     match do |model|
       !model.errors.get(prop.to_sym).blank?
     end
  end

end

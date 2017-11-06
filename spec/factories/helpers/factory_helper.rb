module Helpers
  module FactoryHelper

    def ssn_validator(obj)
      validator = Validations::SocialSecurityValidator.new
      errors = validator.validate(obj)
      errors.present?
    end

    def stubbed_person_ssn(obj, evaluator)
      stubbed_obj = FactoryGirl.build_stubbed(:person, :with_ssn)
      until !ssn_validator stubbed_obj do
        stubbed_obj = FactoryGirl.build_stubbed(:person, :with_ssn)
      end
      evaluator.ssn = stubbed_obj.ssn
    end

    def stubbed_census_employee_ssn(obj, evaluator)
      stubbed_obj = FactoryGirl.build_stubbed(:census_employee)
      until !ssn_validator stubbed_obj do
        stubbed_obj = FactoryGirl.build_stubbed(:census_employee)
      end
      evaluator.ssn = stubbed_obj.ssn
    end
  end
end

# frozen_string_literal: true

module Validators
  module BenefitGroupAssignments
    class BenefitGroupAssignmentContract < ::Dry::Validation::Contract

      params do
        required(:benefit_package_id).filled(Types::Bson)
        required(:start_on).filled(:date)

        optional(:end_on).maybe(:date)
        optional(:hbx_enrollment_id).maybe(Types::Bson)
        optional(:is_active).maybe(:bool)
      end
    end
  end
end

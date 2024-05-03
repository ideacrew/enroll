# frozen_string_literal: true

module Validators
  module ControllerParameters
    module ProductsQhpParameters
      # Strict checking for the hbx_enrollment_id parameter under the 'summary' action.
      class SummaryHbxEnrollmentContract < Dry::Validation::Contract
        params do
          optional(:hbx_enrollment_id).maybe(:string)
        end

        rule(:hbx_enrollment_id) do
          if value.present?
            cast_result = begin
              BSON::ObjectId(value)
            rescue BSON::ObjectId::Invalid
              :invalid_objectid
            end
            key.failure("must be an ObjectId") if cast_result == :invalid_object_id
          end
        end
      end
    end
  end
end

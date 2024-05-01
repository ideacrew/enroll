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
          # rubocop:disable Style/RescueModifier
          # rubocop:disable Lint/EmptyRescueClause
          if value.present?
            cast_result = BSON::ObjectId(value) rescue nil
            key.failure("must be an ObjectId") if cast_result.nil?
          end
          # rubocop:enable Style/RescueModifier
          # rubocop:enable Lint/EmptyRescueClause
        end
      end
    end
  end
end
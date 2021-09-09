# frozen_string_literal: true

module Operations
  module Validators
    module Families
      # dummy file for specs
      class ConsumerRoleContract < Dry::Validation::Contract
        params do
          optional(:is_applying_coverage).filled(:bool)
          optional(:is_applicant).filled(:bool)
          optional(:is_state_resident).maybe(:bool)
          optional(:lawful_presence_determination).maybe(:string)
          optional(:citizen_status).maybe(:string)

        end
      end
    end
  end
end
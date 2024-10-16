# frozen_string_literal: true

module Validators
  module ControllerParameters
    module ProductsQhpParameters
      # Strict checking for the active_year parameter under the 'summary' action.
      class SummaryActiveYearContract < Dry::Validation::Contract
        params do
          required(:active_year).value(:filled?, format?: /\A\s*[0-9][0-9][0-9][0-9]\s*\z/)
        end
      end
    end
  end
end
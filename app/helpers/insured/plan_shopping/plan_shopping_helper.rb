#frozen_string_literal: true

module Insured
  module PlanShopping
    # Helper for conditional plan data display in shopping flow
    module PlanShoppingHelper
      EXCLUDED_CARRIER_ABBREVIATIONS = [
        "GHMSI"
      ].freeze

      def show_provider_directory_url?(plan)
        return false if EXCLUDED_CARRIER_ABBREVIATIONS.include?(plan.issuer_profile.abbrev)
        true
      end
    end
  end
end

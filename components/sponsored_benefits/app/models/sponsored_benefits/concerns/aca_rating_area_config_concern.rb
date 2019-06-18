require 'active_support/concern'

module SponsoredBenefits
  module Concerns::AcaRatingAreaConfigConcern
    extend ActiveSupport::Concern

    included do
      delegate :market_rating_areas, to: :class
      delegate :use_simple_employer_calculation_model?, to: :class
      delegate :sic_field_exists_for_employer?, to: :class
    end

    class_methods do

      def sic_field_exists_for_employer?
        @sic_field ||= Settings.aca.employer_has_sic_field
      end
      def market_rating_areas
        @@market_rating_areas ||= Settings.aca.rating_areas
      end

      def use_simple_employer_calculation_model?
        @@use_simple_employer_calculation_model ||= (Settings.aca.use_simple_employer_calculation_model.to_s.downcase == "true")
      end
    end
  end
end

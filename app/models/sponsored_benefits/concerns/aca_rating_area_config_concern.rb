require 'active_support/concern'

module SponsoredBenefits
  module Concerns::AcaRatingAreaConfigConcern
    extend ActiveSupport::Concern

    included do
      delegate :market_rating_areas, to: :class

    end

    class_methods do
      def market_rating_areas
        @@market_rating_areas ||= Settings.aca.rating_areas
      end
    end
  end
end

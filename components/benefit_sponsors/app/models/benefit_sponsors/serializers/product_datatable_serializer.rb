# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class ProductDatatableSerializer
      include FastJsonapi::ObjectSerializer

      attributes :name, :active_year, :benefit_market_kind, :kind
      attribute :size do
        ''
      end
    end
  end
end

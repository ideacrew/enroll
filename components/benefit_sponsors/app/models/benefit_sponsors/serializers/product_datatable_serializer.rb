# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class ProductDatatableSerializer
      include FastJsonapi::ObjectSerializer

      attributes :name

      attribute :size do
        ''
      end

    end
  end
end

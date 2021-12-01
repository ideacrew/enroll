# frozen_string_literal: true

module BenefitMarkets
  module Locations
    # A County-Zip Code pair.  Used as the building block of the geographic
    # locations covered by both service areas and rating areas.
    class CountyZip
      include Mongoid::Document
      include Mongoid::Timestamps

      field :county_name, type: String
      field :zip, type: String
      field :state, type: String

      index({state: 1, county_name: 1, zip: 1})

      def self.county_names
        Rails.cache.fetch("county-names", expires_in: 12.hours) do
          self.all.map(&:county_name).uniq
        end
      end
    end
  end
end

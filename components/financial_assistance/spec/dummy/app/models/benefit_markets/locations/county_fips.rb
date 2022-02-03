# frozen_string_literal: true

module BenefitMarkets
  module Locations
    class CountyFips
      include Mongoid::Document
      include Mongoid::Timestamps

      field :state_postal_code, type: String
      field :county_fips_code, type: String
      field :county_name, type: String

      index({county_fips_code:  1}, {unique: true})
      index({state_postal_code: 1, county_name: 1})
      index({state_postal_code: 1})
    end
  end
end

module BenefitMarket
  module Locations
    # A County-Zip Code pair.  Used as the building block of the geographic
    # locations covered by both service areas and rating areas.
    class CountyZip
      include Mongoid::Document
      include Mongoid::Timestamps

      field :county_name, type: String
      field :county_code, type: String
      field :zip, type: String
      field :state, type: String
      field :state_code, type: String
    end
  end
end

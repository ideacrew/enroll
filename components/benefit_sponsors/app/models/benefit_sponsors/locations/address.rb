module BenefitSponsors
  module Locations
    class Address
      include Mongoid::Document
      include Mongoid::Timestamps
      include BenefitSponsors::Concerns::Address

    end
  end
end

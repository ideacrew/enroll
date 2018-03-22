module BenefitSponsors
  module Locations
    class Phone
    	include Mongoid::Document
      include Mongoid::Timestamps
      include BenefitSponsors::Concerns::Phone
    end
  end
end
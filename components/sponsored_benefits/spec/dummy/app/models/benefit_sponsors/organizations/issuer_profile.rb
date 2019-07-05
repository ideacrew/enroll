module BenefitSponsors
  module Organizations
    class IssuerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document
    end
  end
end

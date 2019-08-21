module SponsoredBenefits
  module Locations
    class Address
      include Mongoid::Document
      include Mongoid::Timestamps
      include SponsoredBenefits::Concerns::Address

      embedded_in :office_location, class_name: "SponsoredBenefits::Organizations::OfficeLocation"

    end
  end
end

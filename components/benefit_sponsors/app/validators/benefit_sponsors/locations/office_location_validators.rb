module BenefitSponsors
  module Locations
    module OfficeLocationValidators
      PARAMS = Dry::Validation.Params do
        required(:kind).value(included_in?: ["mailing", "branch"])
        required(:phone).schema(BenefitSponsors::ContactInformation::PhoneValidators::PARAMS)
        required(:address).schema(BenefitSponsors::Locations::AddressValidators::PARAMS)
      end
    end
  end
end
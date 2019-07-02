module BenefitSponsors
  module BrokerAgencyRegistration
    module CreateRequestValidators
      PARAMS = Dry::Validation.Params(::BenefitSponsors::BaseParamValidator) do
        required(:legal_name).value(:filled?)
        optional(:dba).maybe(:str?)
        required(:first_name).value(:filled?)
        required(:last_name).value(:filled?)
        required(:npn).value(:filled?)
        required(:dob).value(:us_date?)
        required(:email).value(:filled?, :email?)
        required(:practice_area).value(:filled?)
        required(:accepts_new_clients).value(:filled?, :bool?)
        required(:evening_weekend_hours).value(:filled?, :bool?)

        required(:phone).schema(BenefitSponsors::ContactInformation::PhoneValidators::PARAMS)

        required(:address).schema(BenefitSponsors::Locations::AddressValidators::PARAMS)

        required(:languages).value(:array?, min_size?: 1)

        optional(:office_locations).each(BenefitSponsors::Locations::OfficeLocationValidators::PARAMS)
      end

      DOMAIN = Dry::Validation.Schema(::BenefitSponsors::BaseSchemaValidator) do
        required(:user).value(:filled?)
        required(:request).value(:filled?)

        validate(broker_person_identity_available: [:user, :request]) do |user, request|
          BenefitSponsors::Services::BrokerRegistrationService.may_claim_broker_identity?(user, request)
        end

        validate(only_one_mailing_office_location: [:request]) do |request|
          !request.office_locations.many? do |ol|
            ol.kind == "mailing"
          end
        end
      end
    end
  end
end
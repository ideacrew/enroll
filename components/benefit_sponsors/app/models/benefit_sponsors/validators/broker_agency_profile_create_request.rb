require 'dry-validation'
require 'date'
require 'mail'

module BenefitSponsors
  module Validators
    module BrokerAgencyProfileCreateRequest
      PHONE_PARAMS = Dry::Validation.Params do
        required(:phone_area_code).value(:filled?, format?: /\A[0-9][0-9][0-9]\z/)
        required(:phone_number).value(:filled?, format?: /\A[0-9][0-9][0-9][0-9][0-9][0-9][0-9]\z/)
        optional(:phone_extension).maybe(:filled?, format?: /\Ax?[0-9]+\z/i)
      end

      ADDRESS_PARAMS = Dry::Validation.Params do
        required(:address_1).value(:filled?)
        optional(:address_2).maybe(:str?)
        required(:city).value(:filled?)
        required(:state).value(included_in?: State::NAME_IDS.map(&:last))
        required(:zip).value(:filled?, format?: /\A[0-9][0-9][0-9][0-9][0-9]\z/)
      end

      PARAMS = Dry::Validation.Params do
        configure do
          config.messages = :i18n

          def us_date?(value)
            (Date.strptime(value, "%m/%d/%Y") rescue nil).present?
          end

          def email?(value)
            begin
              parsed = Mail::Address.new(value)
              true
            rescue Mail::Field::ParseError => e
              false
            end
          end
        end

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

        required(:phone).schema(PHONE_PARAMS)

        required(:address).schema(ADDRESS_PARAMS)

        required(:ach_information).schema do
          required(:ach_account).value(:filled?)
          optional(:ach_routing).maybe(:str?)
          optional(:ach_routing_confirmation).maybe(:str?)
        end

        required(:languages).value(:array?, min_size?: 1)

        optional(:office_locations).each do
          required(:kind).value(included_in?: ["mailing", "branch"])
          required(:phone).schema(PHONE_PARAMS)
          required(:address).schema(ADDRESS_PARAMS)
        end
      end

      DOMAIN = Dry::Validation.Schema do
        configure do
          config.messages = :i18n
        end

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

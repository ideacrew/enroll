module BenefitSponsors
  module BrokerAgencyRegistration
    module CreateRequestWithAchValidators

      PARAMS =  Dry::Validation.Params(
        ::BenefitSponsors::BrokerAgencyRegistration::CreateRequestValidators::PARAMS.class
        ) do

        required(:ach_information).schema do
          required(:ach_account).value(:filled?)
          optional(:ach_routing).maybe(:str?)
          optional(:ach_routing_confirmation).maybe(:str?)
        end
      end
    end
  end
end
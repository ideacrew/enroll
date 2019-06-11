require 'dry-initializer'
require 'dry-types'
require 'mail'

module BenefitSponsors
  module Requests
    class AchInformation
      extend Dry::Initializer
      
      option :ach_account, Dry::Types['coercible.string'], optional: true
      option :ach_account, Dry::Types['coercible.string'], optional: true
      option :ach_routing, Dry::Types['coercible.string'], optional: true
      option :ach_routing_confirmation, Dry::Types['coercible.string'], optional: true
    end

    class Address
      extend Dry::Initializer
      option :address_1, Dry::Types['coercible.string'], optional: true
      option :address_2, Dry::Types['coercible.string'], optional: true
      option :city, Dry::Types['coercible.string'], optional: true
      option :state, Dry::Types['coercible.string'], optional: true
      option :zip, Dry::Types['coercible.string'], optional: true
    end

    class Phone
      extend Dry::Initializer
      option :phone_area_code, Dry::Types['coercible.string'], optional: true
      option :phone_number, Dry::Types['coercible.string'], optional: true
      option :phone_extension, Dry::Types['coercible.string'], optional: true
    end

    class OfficeLocation
      extend Dry::Initializer
      option :kind, type: Dry::Types['coercible.string'], optional: true
      option :address, ->(args) { ::BenefitSponsors::Requests::Address.new(args) }, optional: true
      option :phone, ->(args) { ::BenefitSponsors::Requests::Phone.new(args) }, optional: true
    end

    class UsDateCoercer
      def self.coerce(string)
        Date.strptime(string, "%m/%d/%Y") rescue nil
      end
    end

    class BrokerAgencyProfileCreateRequest
      extend Dry::Initializer

      option :legal_name, type: Dry::Types['coercible.string'], optional: true
      option :dba, type: Dry::Types['coercible.string'], optional: true
      option :npn, type: Dry::Types['coercible.string'], optional: true
      option :first_name, type: Dry::Types['coercible.string'], optional: true
      option :last_name, type: Dry::Types['coercible.string'], optional: true
      option :dob, type: ->(val) { UsDateCoercer.coerce(val) }, optional: true
      option :email, type: Dry::Types['coercible.string'], optional: true

      option :practice_area, type: Dry::Types['coercible.string'], optional: true
      option :accepts_new_clients, type: Dry::Types['params.bool'], optional: true
      option :evening_weekend_hours, type: Dry::Types['params.bool'], optional: true
      option :languages, type: Dry::Types['coercible.array'].of(Dry::Types['coercible.string']), optional: true

      option :ach_information, ->(args) { ::BenefitSponsors::Requests::AchInformation.new(args) }, optional: true
      option :address, ->(args) { ::BenefitSponsors::Requests::Address.new(args) }, optional: true
      option :phone, ->(args) { ::BenefitSponsors::Requests::Phone.new(args) }, optional: true

      option :office_locations, type: Dry::Types['coercible.array'].of(->(args) { ::BenefitSponsors::Requests::OfficeLocation.new(args) }), optional: true

      def self.create(opts = {}, user)
        params_validation = ::BenefitSponsors::Validators::BrokerAgencyProfileCreateRequest::PARAMS.call(opts)
        return params_validation unless params_validation.success?
        model = self.new(params_validation.output)
        BenefitSponsors::Services::BrokerRegistrationService.process_creation_request(user, model)
      end
    end
  end
end

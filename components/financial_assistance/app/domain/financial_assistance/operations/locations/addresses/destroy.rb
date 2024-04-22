# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Locations
      module Addresses
        # Destroy class is responsible for destroying a given address.
        #
        # @example
        #   FinancialAssistance::Operations::Locations::Addresses::Destroy.new.call(address)
        class Destroy
          include Dry::Monads[:do, :result]

          # Calls the operation and destroys the address.
          #
          # @param address [FinancialAssistance::Locations::Address] the address to be destroyed
          # @return [Dry::Monads::Result] a monadic result object
          def call(address)
            address = yield validate(address)
            result  = yield destroy_address(address)

            Success(result)
          end

          private

          # Validates the address.
          #
          # @param address [FinancialAssistance::Locations::Address] the address to be validated
          # @return [Dry::Monads::Result] a monadic result object
          def validate(address)
            return Failure("Given input: #{address} is not a valid FinancialAssistance::Locations::Address.") unless address.is_a?(::FinancialAssistance::Locations::Address)

            return Failure('Given address not of kind mailing, cannot be destroyed/deleted.') unless address.mailing?

            @applicant = address.applicant
            application = @applicant.application
            return Failure("The application with hbx_id: #{application.hbx_id} for given applicant with person_hbx_id: #{@applicant.person_hbx_id} is not a draft application, address cannot be destroyed/deleted.") unless application.draft?

            Success(address)
          end

          # Destroys the address.
          #
          # @param address [FinancialAssistance::Locations::Address] the address to be destroyed
          # @return [Dry::Monads::Result] a monadic result object
          def destroy_address(address)
            address.destroy!
            Success(
              "Successfully destroyed mailing address of the applicant with full_name: #{
                @applicant.full_name} and person_hbx_id: #{@applicant.person_hbx_id}."
            )
          rescue StandardError => e
            Failure(
              "Unable to destroy mailing address of the applicant with full_name: #{
                @applicant.full_name} and person_hbx_id: #{@applicant.person_hbx_id} with error: #{e.message}."
            )
          end
        end
      end
    end
  end
end

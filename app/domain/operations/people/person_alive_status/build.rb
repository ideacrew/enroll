# frozen_string_literal: true

module Operations
  module People
    module PersonAliveStatus
      # This class is responsible adding an alive status verification type
      # and demographics_group with nested alive_status if needed
      class Build
        include Dry::Monads[:result, :do]
        include EventSource::Command
        include EventSource::Logging

        # Builds AliveStatus-related objects for valid persons
        # Used by 
        #
        # @param params [Person] The parameters to use for the migration.
        # @return [Dry::Monads::Result] A result object.
        def call(params)
          valid_person = yield validate(params)
          yield build_and_save_alive_status(valid_person)

          Success("Successfully Migrated Person Alive Status")
        end

        private

        # Validates the parameters for the migration.
        #
        # @param person [Person] The parameters to validate.
        # @return [Dry::Monads::Result] A result object.
        def validate(person)
          return Failure("Invalid person object") unless person.is_a?(Person)
          return Failure("Person does not have consumer role") unless person.consumer_role.present?

          Success(person)
        end

        # Builds AliveStatus-related objects for the person.
        #
        # @param person [Person] The person to migrate.
        # @return [Dry::Monads::Result] A result object.
        def create_alive_status(person)
          payload = build_demographics_group_payload
          person.create_demographics_group(payload) unless person&.demographics_group && person&.demographics_group&.alive_status

          return Success(person) unless person&.ssn && person.verification_types.alive_status_type.empty?

          person.add_new_verification_type("Alive Status")
          person.verification_types.where(type_name: "Alive Status").first.save!
          person.consumer_role.update_family_document_status

          Success(person)
        rescue StandardError => e
          Failure(e.inspect)
        end

        # Builds the payload for the demographics group.
        #
        # @return [Hash] The payload.
        def build_demographics_group_payload
          { alive_status: { is_deceased: false, date_of_death: nil }}
        end
      end
    end
  end
end
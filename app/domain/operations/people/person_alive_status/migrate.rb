# frozen_string_literal: true

# Start
#   |
#   v
# Call Method
#   |
#   v
# Validate Parameters
#   |<------------------+
#   v                  |
# Find Person          |
#   |                  |
#   v                  |
# Migrate Person       |
#   |                  |
#   v                  |
# Build Family Determination
#   |                  |
#   v                  |
# End <----------------+

module Operations
  module People
    module PersonAliveStatus
      # This class is responsible for migrating the alive status of a person.
      class Migrate
        include Dry::Monads[:result, :do]
        include EventSource::Command
        include EventSource::Logging

        # Migrates the alive status of a person.
        #
        # @param params [Hash] The parameters to use for the migration.
        # @option params [Integer] :person_id The ID of the person to migrate.
        # @return [Dry::Monads::Result] A result object.
        def call(params)
          values = yield validate(params)
          person = yield find_person(values)
          yield migrate(person)
          yield build_family_determination(person.families)

          Success("Successfully Migrated Person Alive Status")
        end

        private

        # Validates the parameters for the migration.
        #
        # @param params [Hash] The parameters to validate.
        # @return [Dry::Monads::Result] A result object.
        def validate(params)
          errors = []
          errors << 'person_id ref missing' unless params[:person_id]
          errors << "alive_status feature is disabled" unless EnrollRegistry.feature_enabled?(:alive_status)
          errors.empty? ? Success(params) : log_error_and_return_failure(errors)
        end

        # Finds the person to migrate.
        #
        # @param params [Hash] The parameters to use to find the person.
        # @return [Dry::Monads::Result] A result object.
        def find_person(params)
          person = Person.find(params[:person_id])
          person.present? ? Success(person) : Failure("Person not found with id: #{params[:person_id]}")
        end

        # Builds the payload for the demographics group.
        #
        # @return [Hash] The payload.
        def build_demographics_group_payload
          { alive_status: { is_deceased: false, date_of_death: nil }}
        end

        # Migrates the person.
        #
        # @param person [Person] The person to migrate.
        # @return [Dry::Monads::Result] A result object.
        def migrate(person)
          #BuildDemographicsGroup
          payload = build_demographics_group_payload
          person.demographics_group.create!(payload)

          if ssn.present?
            person.add_new_verification_type("Alive Status")
            person.alive_status_type.save!
            person.families.each(&:update_family_document_status!)
          end

          Success(person)
        rescue StandardError => e
          Failure(e.message)
        end

        # Builds the family determination.
        #
        # @param families [Array<Family>] The families to build the determination for.
        # @return [void]
        def build_family_determination(families)
          families.each do |family|
            result = ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: family, effective_date: TimeKeeper.date_of_record)
            return Failure(result.errors) if result.failure?
          end

          Success()
        end
      end
    end
  end
end
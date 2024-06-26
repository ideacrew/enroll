# frozen_string_literal: true

# Start
#   |
#   v
# Call Method
#   |
#   v
# Validate Parameters
#   |<-----------------+
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
          errors << 'person_id ref missing' unless params[:person_hbx_id]
          errors << "alive_status feature is disabled" unless EnrollRegistry.feature_enabled?(:alive_status)
          errors.empty? ? Success(params) : Failure(errors)
        end

        # Finds the person to migrate.
        #
        # @param params [Hash] The parameters to use to find the person.
        # @return [Dry::Monads::Result] A result object.
        def find_person(params)
          ::Operations::People::Find.new.call(person_hbx_id: params[:person_hbx_id])
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
          return Failure("Person does not have consumer role") unless person.consumer_role.present?

          payload = build_demographics_group_payload
          person.create_demographics_group(payload) unless person.demographics_group.present? && person.demographics_group.alive_status.present?

          return Success(person) unless person.ssn.present? && person.verification_types.alive_status_type.empty?

          person.add_new_verification_type("Alive Status")
          person.verification_types.where(type_name: "Alive Status").first.save!
          person.families.each(&:update_family_document_status!)

          Success(person)
        rescue StandardError => e
          Failure(e.inspect)
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
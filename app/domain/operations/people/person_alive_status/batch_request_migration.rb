# frozen_string_literal: true

module Operations
  module People
    module PersonAliveStatus
      # This class is responsible for migrating the alive status of a person.
      class BatchRequestMigration
        include Dry::Monads[:result, :do]
        include EventSource::Command
        include EventSource::Logging


        def call(params)
          values = yield validate(params)
          people = yield fetch_people_with_consumer_role(values)
          yield publish(people)

          Success("Successfully Migrated Person Alive Status")
        end

        private

        def validate(params)
          errors = []
          errors << 'person_id ref missing' unless params[:person_id]
        end

        def fetch_people_with_consumer_role(_params)
          Person.exists(consumer_role: true)
        end
      end
    end
  end
end
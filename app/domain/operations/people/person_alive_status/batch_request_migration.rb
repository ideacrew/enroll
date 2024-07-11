# frozen_string_literal: true

# Operations::People::PersonAliveStatus::BatchRequestMigration.new.call

module Operations
  module People
    module PersonAliveStatus
      # This class is responsible for migrating the alive status of a person.
      class BatchRequestMigration
        include Dry::Monads[:result, :do]
        include EventSource::Command
        include EventSource::Logging

        def call
          people = yield fetch_people_with_consumer_role
          batch_process(people)
        end

        private

        def fetch_people_with_consumer_role
          result = Person.exists(consumer_role: true, encrypted_ssn: true, demographics_group: false)

          if result.present?
            Success(result)
          else
            Failure("No people found with consumer role")
          end
        end

        def build_and_publish_event(person)
          event = event('events.people.person_alive_status.data_migration.requested', attributes: { person_hbx_id: person.hbx_id })

          if event.success?
            Success(event.success.publish)

          else
            Failure(event.failure)
          end
        end

        def batch_process(people)
          field_names = %w[HBX_ID Published?]
          file_name = "#{Rails.root}/alive_status_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
          counter = 0

          CSV.open(file_name, 'w', force_quotes: true) do |csv|
            csv << field_names
            people.each do |person|
              result = build_and_publish_event(person)
              counter += 1 if result.success?
              csv << [person.hbx_id, result.success?]
            end
          end

          Success("Successfully processed batch request for #{counter} people. Report is generated at #{file_name}")
        end
      end
    end
  end
end
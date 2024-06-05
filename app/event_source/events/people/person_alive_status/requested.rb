# frozen_string_literal: true

module Events
  module People
    module PersonAliveStatus
      module DataMigration
        # This class will register event under 'ivl_osse_eligibility_publisher'
        class Requested < EventSource::Event
          publisher_path "publishers.people.person_alive_status.data_migration_requested_publisher"

        end
      end
    end
  end
end

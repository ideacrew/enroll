# frozen_string_literal: true

module Publishers
  module People
    module PersonAliveStatus
          # Publisher will send request to EA to create renewal drafts
      class DataMigrationRequestedPublisher
        include ::EventSource::Publisher[amqp: 'enroll.people.person_alive_status.data_migration']

        register_event 'requested'
      end
    end
  end
end

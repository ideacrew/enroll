
# frozen_string_literal: true

module Publishers
  # Publishes changes to ConsumerRole and Family to Sugar CRM
  class FamilyPublisher
    include ::EventSource::Publisher[amqp: 'enroll.family_updates']

    register_event 'family_update'
  end
end

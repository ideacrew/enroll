# frozen_string_literal: true

module Publishers
  module Private
    class FamilyMemberPublisher
      include ::EventSource::Publisher[amqp: 'enroll.private']

      register_event 'family_member_created'
    end
  end
end
# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # This class will register event 'corrected1095a_notice.requested'
      class Corrected1095aNoticeRequestedPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.families.notices.corrected1095a_notice']

        register_event 'requested'
      end
    end
  end
end


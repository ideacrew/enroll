# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # This class will register event 'initial1095a_notice.requested'
      class Initial1095NoticeRequestedPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.families.notices.initial1095a_notice']

        register_event 'requested'
      end
    end
  end
end


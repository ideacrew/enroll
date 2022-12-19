# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # This class will register event 'fre_notice_generation.requested'
      class FreNoticeGenerationRequestedPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.families.notices.fre_notice_generation']

        register_event 'requested'
      end
    end
  end
end


# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # This class will register event 'fre_notice_generation.requested'
      class FaaTotallyIneligibleNoticeRequestedPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.families.notices.faa_totally_ineligible_notice']

        register_event 'requested'
      end
    end
  end
end

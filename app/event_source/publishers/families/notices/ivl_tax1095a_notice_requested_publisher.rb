# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # This class will register events for form 1095a notices
      class IvlTax1095aNoticeRequestedPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.families.notices.ivl_tax1095a']

        register_event 'initial_notice_requested'
        register_event 'catastrophic_notice_requested'
        register_event 'void_notice_requested'
        register_event 'corrected_notice_requested'
      end
    end
  end
end


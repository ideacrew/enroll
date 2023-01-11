# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      module IvlTax1095a
      # This class will register event 'catastrophic1095a_notice.requested'
        class CatastrophicNoticeRequestedPublisher < EventSource::Event
          include ::EventSource::Publisher[amqp: 'enroll.families.notices.ivl_tax1095a']

          register_event 'initial_notice_requested'
          register_event 'catastrophic_notice_requested'
          register_event 'void_notice_requested'
          register_event 'corrected_notice_requested'
        end
      end
    end
  end
end


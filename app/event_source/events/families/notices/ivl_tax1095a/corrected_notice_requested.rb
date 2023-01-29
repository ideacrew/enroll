# frozen_string_literal: true

module Events
  module Families
    module Notices
      module IvlTax1095a
        # This class will register event 'corrected1095a_notice.requested'
        class CorrectedNoticeRequested < EventSource::Event
          publisher_path 'publishers.families.notices.ivl_tax1095a_notice_requested_publisher'

        end
      end
    end
  end
end


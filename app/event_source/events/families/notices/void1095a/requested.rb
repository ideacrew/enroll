# frozen_string_literal: true

module Events
  module Families
    module Notices
      module Void1095a
        # This class will register event 'void1095a_notice.requested'
        class Requested < EventSource::Event
          publisher_path 'publishers.families.notices.void1095a_notice_requested_publisher'

        end
      end
    end
  end
end


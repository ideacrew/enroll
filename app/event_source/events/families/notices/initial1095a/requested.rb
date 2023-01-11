# frozen_string_literal: true

module Events
  module Families
    module Notices
      module Initial1095a
        # This class will register event 'fre_notice_generation.requested'
        class Requested < EventSource::Event
          publisher_path 'publishers.families.notices.initial1095a_notice_requested_publisher'

        end
      end
    end
  end
end


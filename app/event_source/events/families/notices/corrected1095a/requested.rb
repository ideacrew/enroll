# frozen_string_literal: true

module Events
  module Families
    module Notices
      module Corrected1095a
        # This class will register event 'fre_notice_generation.requested'
        class Requested < EventSource::Event
          publisher_path 'publishers.families.notices.corrected1095a_requested_publisher'

        end
      end
    end
  end
end


# frozen_string_literal: true

module Events
  module Families
    module Notices
      module Catastrophic1095a
        # This class will register event 'fre_notice_generation.requested'
        class Requested < EventSource::Event
          publisher_path 'publishers.families.notices.catastrophic1095a_requested_publisher'

        end
      end
    end
  end
end


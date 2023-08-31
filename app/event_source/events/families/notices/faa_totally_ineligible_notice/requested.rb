# frozen_string_literal: true

module Events
  module Families
    module Notices
      module FaaTotallyIneligibleNotice
        # This class will register event 'faa_totally_ineligible_notice.requested'
        class Requested < EventSource::Event
          publisher_path 'publishers.families.notices.faa_totally_ineligible_notice_requested_publisher'
        end
      end
    end
  end
end

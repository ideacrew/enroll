# frozen_string_literal: true

module Events
  module Reports
    # This class will register event
    class GeneratePreauditReport < EventSource::Event
      publisher_path 'publishers.preaudit_report_generation_publisher'
    end
  end
end
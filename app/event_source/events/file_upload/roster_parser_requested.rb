# frozen_string_literal: true

module Events
  module FileUpload
    # This class has publisher path to register event
    class RosterParserRequested < EventSource::Event
      publisher_path 'publishers.file_upload.roster_parser_requested_publisher'
    end
  end
end
  
# frozen_string_literal: true

module Publishers
  module FileUpload
    # Publishes changes to ConsumerRole and Family to Sugar CRM
    class RosterParserRequestedPublisher
      include ::EventSource::Publisher[amqp: 'enroll.file_upload']

      register_event 'roster_parser_requested'
    end
  end
end
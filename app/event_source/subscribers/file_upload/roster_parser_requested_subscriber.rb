# frozen_string_literal: true

module Subscribers
  module FileUpload
  # Subscriber will receive Enterprise requests like date change
    class RosterParserRequestedSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.file_upload']

      subscribe(
        :on_roster_parser_requested
      ) do |delivery_info, _metadata, response|

        logger.info response

        # this is where you should parse the xls file
        # by an operation

        ack(delivery_info.delivery_tag)

      rescue StandardError, SystemStackError => e
        logger.error "something happened"


        ack(delivery_info.delivery_tag)
      end
    end
  end
end

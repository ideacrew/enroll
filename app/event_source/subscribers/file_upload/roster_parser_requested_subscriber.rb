# frozen_string_literal: true

module Subscribers
  module FileUpload
  # Subscriber will receive Enterprise requests like date change
    class RosterParserRequestedSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.file_upload']

      subscribe(
        :on_roster_parser_requested
      ) do |delivery_info, _metadata, response|
        parsed_response = JSON.parse(response)
        uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{parsed_response['bucket_name']}##{parsed_response['s3_reference_key']}"
        result = Operations::Employer::Roster::CreateEmployeeModel.new.call({uri: uri, employer_profile_id: parsed_response["employer_profile_id"], extension: parsed_response["extension"]})
        begin
          if result.success?
            logger.info "FileUpload::RosterParserSubscriber: on_primary_determination acked with success: #{result.success}"
          else
            errors = result.failure&.errors&.to_h
            logger.info "FileUpload::RosterParserSubscriber: on_primary_determination acked with failure, errors: #{errors}"
          end
        rescue StandardError => e
          logger.info "FileUpload::RosterParserSubscriber: on_primary_determination error: #{e.backtrace}"
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.info "FileUpload::RosterParserSubscriber: on_primary_determination error: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end
    end
  end
end

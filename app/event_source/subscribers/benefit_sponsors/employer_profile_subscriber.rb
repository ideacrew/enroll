# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to employer profile
    class EmployerProfileSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.employer_profile']

      subscribe(:on_bulk_ce_upload) do |delivery_info, _metadata, response|
        logger.info '-' * 100

        payload = JSON.parse(response)
        uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{payload['bucket_name']}##{payload['s3_reference_key']}"

        extension = payload[:extension]
        employer_profile_id = payload[:employer_profile_id]
        result = Operations::BenefitSponsors::EmployerProfile::BulkCeUpload.new.call(uri: uri, employer_profile_id: employer_profile_id, extension: extension)
        begin
          if result.success?
            logger.info "EmployerProfileSubscriber: on_primary_determination acked with success: #{result.success}"
          else
            errors = result.failure&.errors&.to_h
            logger.info "EmployerProfileSubscriber: on_primary_determination acked with failure, errors: #{errors}"
          end
        rescue StandardError => e
          logger.info "EmployerProfileSubscriber: on_primary_determination error: #{e.backtrace}"
        ensure
          Aws::S3Storage.delete_file(parsed_response['bucket_name'], parsed_response['s3_reference_key'])
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.info "EmployerProfileSubscriber: on_primary_determination error: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_employer_profile_bulk_employee_upload_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end



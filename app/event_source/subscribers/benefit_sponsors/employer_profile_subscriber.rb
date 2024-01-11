# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to employer profile
    class EmployerProfileSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.employer_profile']

      subscribe(:on_bulk_ce_upload) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        logger.debug "invoked EmployerProfileSubscriber with #{delivery_info}"

        payload = JSON.parse(response, symbolize_names: true)

        filename = payload[:filename]
        employer_profile_id = payload[:employer_profile_id]
        s3_uri = payload[:s3_uri]

        subscriber_logger.info "EmployerProfileSubscriber on_bulk_ce_upload payload: #{payload}"
        subscriber_logger.info "EmployerProfileSubscriber, uri: #{s3_uri}, filename: #{filename}, employer_profile_id: #{employer_profile_id}"

        result = Operations::BenefitSponsors::EmployerProfile::BulkCeUpload.new.call(uri: s3_uri, employer_profile_id: employer_profile_id, filename: filename)

        begin
          if result.success?
            subscriber_logger.info "EmployerProfileSubscriber: on_bulk_ce_upload acked with success: #{result.success}"
            logger.info "BulkCeUpload: acked, SuccessResult: #{result.success}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "EmployerProfileSubscriber: on_bulk_ce_upload acked with failure, errors: #{errors}"
            logger.info "BulkCeUpload: acked, FailureResult, errors: #{errors}"
          end
        rescue StandardError => e
          logger.error "EmployerProfileSubscriber: on_bulk_ce_upload error_message: #{e.message}, backtrace: #{e.backtrace}"
        ensure
          Aws::S3Storage.delete_file(payload[:bucket_name], payload[:s3_reference_key])
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error "EmployerProfileSubscriber: on_bulk_ce_upload error_message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/employer_profile_subscriber_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end



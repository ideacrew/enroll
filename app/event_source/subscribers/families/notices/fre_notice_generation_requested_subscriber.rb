# frozen_string_literal: true

module Subscribers
  module Families
    module Notices
      # Subscriber will receive request payload contains family id from EA to generate fre notice
      class FreNoticeGenerationRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.families.notices.fre_notice_generation']

        subscribe(:on_enroll_families_notices_fre_notice_generation) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)

          subscriber_logger =
            Logger.new("#{Rails.root}/log/FreNoticeGenerationRequestedSubscriber_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          subscriber_logger.info "on_enroll_families_notices_fre_notice_generation, response: #{payload}"

          logger.info "on_enroll_families_notices_fre_notice_generation FreNoticeGenerationRequestedSubscriber payload: #{payload}"
          logger.debug "invoked FreNoticeGenerationRequestedSubscriber with #{delivery_info}"

          family = Family.where("id": payload[:family_id]).first
          result = Operations::Notices::IvlFinalRenewalEligibilityNotice.new.call(family: family)
          person_hbx_id = family&.primary_applicant&.hbx_id

          if result.success?
            subscriber_logger.info "on_enroll_families_notices_fre_notice_generation, success: person_hbx_id: #{person_hbx_id} | result: #{result.value!}"
            logger.info "on_enroll_families_notices_fre_notice_generation: acked, SuccessResult: person_hbx_id: #{person_hbx_id} | #{result.value!}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "on_enroll_families_notices_fre_notice_generation, failure: person_hbx_id: #{person_hbx_id} | #{errors}"
            logger.info "on_enroll_families_notices_fre_notice_generation: acked, FailureResult: person_hbx_id: #{person_hbx_id} | #{errors}"
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info "on_enroll_families_notices_fre_notice_generation, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          logger.info "on_enroll_families_notices_fre_notice_generation: errored & acked. Backtrace: #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end

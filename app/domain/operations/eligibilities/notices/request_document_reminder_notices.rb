# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Notices
      # Create document reminder notice requests based on date passed in
      class RequestDocumentReminderNotices
        send(:include, Dry::Monads[:result, :do])
        include EventSource::Command
        include EventSource::Logging

        # @param [Hash] opts Options to trigger document reminder notice requests
        # @option opts [Date] :date_of_record required
        # @return [Dry::Monad] result
        def call(params)
          values = yield validate(params)
          notices = yield get_reminder_notices(values)
          results = yield request_notices(values, notices)
          event = yield publish_event(results)

          Success(event)
        end

        private

        def validate(params)
          errors = []
          errors << 'date of record missing' unless params[:date_of_record]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def get_reminder_notices(_values)
          document_reminder_notices =
            EnrollRegistry[:ivl_eligibility_notices].settings(
              :document_reminders
            ).item

          Success(document_reminder_notices)
        end

        def request_notices(values, notices)
          response =
            notices.reduce({}) do |notices_output, document_reminder_key|
              offset_prior_due_date =
                offset_prior_to_due_date(document_reminder_key)
              families =
                Family.outstanding_verifications_expiring_on(
                  values[:date_of_record] + offset_prior_due_date
                )

              result_set =
                families.reduce(
                  { successes: [], failures: [] }
                ) do |results, family|
                  result =
                    process_notice_request(
                      family,
                      document_reminder_key,
                      values
                    )

                  if result.success?
                    results[:successes].push(
                      { family_hbx_id: family.hbx_assigned_id }
                    )
                  else
                    results[:failures].push(
                      {
                        family_hbx_id: family.hbx_assigned_id,
                        error: result.failure
                      }
                    )
                  end
                  results
                end

              notices_output[document_reminder_key] = result_set
              notices_output
            end

          Success(response)
        end

        def process_notice_request(family, document_reminder_key, values)
          result =
            CreateReminderRequest.new.call(
              document_reminder_key: document_reminder_key,
              family: family,
              date_of_record: values[:date_of_record]
            )

          if result.failure?
            Rails
              .logger.info "Error #{result.failure} generating #{document_reminder_key} notice for family #{family.hbx_assigned_id}"
          end

          result
        rescue StandardError => e
          Rails
            .logger.info "Error #{e.backtrace} generating #{document_reminder_key} notice for family #{family.hbx_assigned_id}"
        end

        def offset_prior_to_due_date(document_reminder_key)
          feature = EnrollRegistry[document_reminder_key]

          offset = feature.settings(:offset_prior_to_due_date).item
          units = feature.settings(:units).item

          offset.send(units)
        end

        def publish_event(results)
          event_key = 'events.enterprise.document_reminder_notices_processed'

          event_result = event(event_key, attributes: results)
          event = event_result.success

          unless Rails.env.test?
            logger.info('-' * 100)
            logger.info(
              "Enroll Reponse Publisher to external systems(polypress),
            event_key: #{event_key}, attributes: #{payload.to_h}, result: #{event}"
            )
            logger.info('-' * 100)
          end

          event.publish if event_result.success?
          event_result
        end
      end
    end
  end
end


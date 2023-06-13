# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Osse
      # Terminate eligibility for the subject with given eligibility and termination date
      class TerminateEligibility
        send(:include, Dry::Monads[:result, :do])
        include EventSource::Command
        include EventSource::Logging

        # @param [Hash] opts Options to build eligibility
        # @option opts [<GlobalID>] :subject_gid required
        # @option opts [<String>]   :evidence_key required
        # @option opts [Date]       :termination_date required
        # @return [Dry::Monad] result
        def call(params)
          values        = yield validate(params)
          eligibilities = yield terminate(values)
          event         = yield build_event(eligibilities)
          output        = yield publish_event(event)

          Success(output)
        end

        private

        def validate(params)
          errors = []
          errors << 'subject global id missing' unless params[:subject_gid]
          errors << 'evidence key missing' unless params[:evidence_key]
          errors << 'termination date missing' unless params[:termination_date]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def terminate(values)
          subject_instance = GlobalID::Locator.locate(values[:subject_gid])
          termination_date = values[:termination_date].to_date
          evidence_key = values[:evidence_key]

          eligibilities =
            subject_instance.eligibilities.with_evidence(evidence_key)

          eligibilities.each do |eligibility|
            evidence = eligibility.evidences.new
            evidence.title = "#{evidence_key.to_s.titleize} Evidence"
            evidence.key = evidence_key
            evidence.is_satisfied = false
            evidence.save!

            eligibility.end_on = termination_date if update_end_on?(
              eligibility,
              termination_date
            )
            eligibility.save! if eligibility.changed?
          end

          Success(eligibilities)
        end

        def update_end_on?(eligibility, termination_date)
          eligibility.end_on.nil? ||
            (
              eligibility.end_on.present? &&
                eligibility.end_on > termination_date
            )
        end

        def build_event(payload)
          result = event('events.hc4cc.eligibility_terminated', attributes: payload)

          unless Rails.env.test?
            logger.info('-' * 100)
            logger.info(
              "Enroll Publisher to external systems(polypress),
              event_key: events.hc4cc.eligibility_terminated, attributes: #{payload}, result: #{result}"
            )
            logger.info('-' * 100)
          end
          result
        end

        def publish_event(event)
          Success(event.publish)
        end
      end
    end
  end
end

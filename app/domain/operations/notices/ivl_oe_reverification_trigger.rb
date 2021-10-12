# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL open enrollment reverification notice
    class IvlOeReverificationTrigger
      include Dry::Monads[:result, :do]
      include EventSource::Command
      include EventSource::Logging

      # @param [Family] family object (required)
      # @return [Dry::Monads::Result]

      def call(params)
        _values = yield validate(params)
        event_name = yield determine_event_name(params[:family])
        payload = yield build_payload(params[:family])
        event = yield build_event(payload, event_name)
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?

        Success(params)
      end

      def fetch_application(family)
        applications = ::FinancialAssistance::Application.where(family_id: family.id, assistance_year: TimeKeeper.date_of_record.next_year.year)

        determined_applications = applications.where(aasm_state: 'determined')
        return determined_applications.max_by(&:created_at) if determined_applications.present?

        applications.max_by(&:created_at)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def determine_event_name(family)
        financial_application = fetch_application(family)

        return Success('qhp_eligible_on_reverification') if financial_application.nil?
        return Success('expired_consent_on_reverification') unless financial_application.determined?

        applicants = financial_application.applicants

        event_name =
          if applicants.all?(&:is_ia_eligible)
            'aqhp_eligible_on_reverification'
          elsif applicants.all? { |applicant| applicant.is_medicaid_chip_eligible || applicant.is_magi_medicaid }
            'medicaid_eligible_on_reverification'
          elsif applicants.all?(&:is_without_assistance)
            'uqhp_eligible_on_reverification'
          end

        event_name.present? ? Success(event_name) : Failure("Unable to determine event for the given family id: #{family.id}")
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def build_payload(family)
        financial_application = fetch_application(family)

        entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(
          JSON.parse(financial_application.eligibility_response_payload,:symbolize_name => true)
        )

        if entity.success?
          Success(entity.success.to_h)
        else
          Failure("Error parsing the payload for the given family id: #{family.id}")
        end
      end

      def build_event(payload, event_name)
        result = event("events.individual.notices.#{event_name}", attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: events.individual.notices.#{event_name}, attributes: #{payload.to_h}, result: #{result}"
          )
          logger.info('-' * 100)
        end
        result
      end

      def publish_response(event)
        Success(event.publish)
      end
    end
  end
end

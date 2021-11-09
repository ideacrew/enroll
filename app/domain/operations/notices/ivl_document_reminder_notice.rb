# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL document reminder notice
    class IvlDocumentReminderNotice
      include Dry::Monads[:result, :do]
      include EventSource::Command
      include EventSource::Logging

      # @param [Family] :family Family
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate(params)
        event_name = yield fetch_event_for_document_reminder(values[:family])
        _due_dates = yield update_due_dates(values[:family])
        family_hash = yield transform_family(values[:family])
        validate_hash = yield validate_payload(family_hash)
        payload = yield construct_payload(validate_hash)
        event = yield build_event(payload, event_name)
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?

        Success(params)
      end

      # returns latest determined application
      def fetch_application(family)
        ::FinancialAssistance::Application.where(family_id: family.id).determined.max_by(&:created_at)
      end

      def transform_family(family)
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        return result unless result.success?

        application = fetch_application(family)
        family_hash = result.value!
        if application.present?
          app_hash = family_hash[:magi_medicaid_applications].find { |a| a[:hbx_id] == application.hbx_id }
          family_hash[:magi_medicaid_applications] = [app_hash]
        end
        family_hash[:min_verification_due_date] = document_due_date(family)
        updated_hash = modify_enrollments_hash(family_hash, family)

        Success(updated_hash)
      end

      def document_due_date(family)
        (family.min_verification_due_date.present? && (family.min_verification_due_date > todays_date)) ? family.min_verification_due_date : min_notice_due_date(family)
      end

      def valid_enrollment_states
        ['coverage_selected', 'auto_renewing', 'unverified']
      end

      def enrollment_criteria(hbx_enrollment, year)
        valid_enrollment_states.include?(hbx_enrollment[:aasm_state]) &&
          hbx_enrollment[:product_reference] &&
          hbx_enrollment[:product_reference][:active_year] == year
      end

      def modify_enrollments_hash(family_hash, family)
        return family_hash unless family.enrollments.present?

        family_hash[:households].each do |household|
          perspective_enrollments = household[:hbx_enrollments].select do |hbx_enrollment|
            enrollment_criteria(hbx_enrollment, TimeKeeper.date_of_record.next_year.year)
          end.presence
          current_enrollments = household[:hbx_enrollments].select do |hbx_enrollment|
            enrollment_criteria(hbx_enrollment, TimeKeeper.date_of_record.year)
          end.presence
          household[:hbx_enrollments] = perspective_enrollments || current_enrollments
        end
        family_hash
      end

      def validate_payload(payload)
        result = ::AcaEntities::Contracts::Families::FamilyContract.new.call(payload)
        return Failure("Unable to validate payload") unless result.success?

        Success(result.to_h)
      end

      def construct_payload(values)
        result = AcaEntities::Families::Family.new(values)

        Success(result.to_h)
      end

      def todays_date
        TimeKeeper.date_of_record
      end

      def update_due_dates(family)
        update_individual_due_date_on_verification_types(family)
        update_individual_due_date_on_evidences(family)
        update_due_date_on_family(family)

        Success(true)
      end

      def min_notice_due_date(family)
        due_dates = []
        family.contingent_enrolled_active_family_members.each do |family_member|
          family_member.person.verification_types.each do |v_type|
            due_dates << family.document_due_date(v_type)
          end
        end
        application = fetch_application(family)
        application&.applicants&.each do |applicant|
          applicant.unverified_evidences.each do |evidence|
            due_dates << evidence.due_on.to_date
          end
        end

        due_dates.compact!
        earliest_future_due_date = due_dates.select { |due_date| due_date > todays_date }.min
        earliest_future_due_date.to_date if due_dates.present? && earliest_future_due_date.present?
      end

      # updates minimum verification due date on family
      def update_due_date_on_family(family)
        family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family) unless family.min_verification_due_date.present?
      end

      def update_individual_due_date_on_evidences(family)
        application = fetch_application(family)
        return unless application.present?

        application.applicants.each do |applicant|
          applicant.unverified_evidences.each do |evidence|
            unless evidence.due_on.present?
              evidence.update_attributes(due_on: todays_date + Settings.aca.individual_market.verification_due.days, update_reason: 'notice')
              applicant.save!
            end
          end
        end
      end

      def update_individual_due_date_on_verification_types(family)
        family.family_members.map(&:person).each do |person|
          next unless person.consumer_role.present?

          person.consumer_role.types_include_to_notices.each do |verification_type|
            unless verification_type.due_date && verification_type.due_date_type
              verification_type.update_attributes(due_date: todays_date + Settings.aca.individual_market.verification_due.days, due_date_type: "notice")
              person.consumer_role.save!
            end
          end
        end
      end

      def fetch_event_for_document_reminder(family)
        return Success('events.individual.notices.verifications_reminder') if family.min_verification_due_date.nil?

        event =
          case (family.best_verification_due_date.to_date.mjd - todays_date.mjd)
          when 85
            "first_verifications_reminder"
          when 70
            "second_verifications_reminder"
          when 45
            "third_verifications_reminder"
          when 30
            "fourth_verifications_reminder"
          end
        return Failure("No verifications event found for family id: #{family.id} for #{todays_date.to_date}") if event.nil?

        Success("events.individual.notices.#{event}")
      end

      def build_event(payload, event_key)
        result = event(event_key, attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: #{event_key}, attributes: #{payload.to_h}, result: #{result}"
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

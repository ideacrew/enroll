# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Notices
      # Create document reminder notice for the family
      class BuildCvPayload
        send(:include, Dry::Monads[:result, :do])
        include EventSource::Command

        # @param [Hash] opts Options to trigger document reminder notice requests
        # @option opts [Family] :family required
        # @return [Dry::Monad] result
        def call(params)
          values = yield validate(params)
          cv_payload_params = yield build_family_cv_payload(values[:family])
          cv_payload_values = yield validate_payload(cv_payload_params)
          cv_payload = yield create_entity(cv_payload_values)

          Success(cv_payload)
        end

        private

        def validate(params)
          errors = []
          errors << 'family missing' unless params[:family]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build_family_cv_payload(family)
          result =
            Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
          if result.success?
            application = fetch_application(family)
            family_hash = result.value!
            if application.present?
              app_hash =
                family_hash[:magi_medicaid_applications].find do |a|
                  a[:hbx_id] == application.hbx_id
                end
              family_hash[:magi_medicaid_applications] = [app_hash]
            end
            family_hash[:min_verification_due_date] = document_due_date(family)
            updated_hash = modify_enrollments_hash(family_hash, family)

            Success(updated_hash)
          else
            result
          end
        end

        def fetch_application(family)
          ::FinancialAssistance::Application
            .where(family_id: family.id)
            .determined
            .max_by(&:created_at)
        end

        def document_due_date(family)
          if family.min_verification_due_date.present? &&
             (family.min_verification_due_date > todays_date)

            family.min_verification_due_date
          else
            min_notice_due_date(family)
          end
        end

        def min_notice_due_date(family)
          due_dates = []
          family.contingent_enrolled_active_family_members
                .each do |family_member|
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
          earliest_future_due_date =
            due_dates.select { |due_date| due_date > todays_date }.min
          earliest_future_due_date.to_date if due_dates.present? && earliest_future_due_date.present?
        end

        def valid_enrollment_states
          %w[coverage_selected auto_renewing unverified]
        end

        def enrollment_criteria(hbx_enrollment, year)
          valid_enrollment_states.include?(hbx_enrollment[:aasm_state]) &&
            hbx_enrollment[:product_reference] &&
            hbx_enrollment[:product_reference][:active_year] == year
        end

        def modify_enrollments_hash(family_hash, family)
          return family_hash unless family.enrollments.present?

          family_hash[:households].each do |household|
            perspective_enrollments =
              household[:hbx_enrollments].select do |hbx_enrollment|
                enrollment_criteria(
                  hbx_enrollment,
                  TimeKeeper.date_of_record.next_year.year
                )
              end.presence
            current_enrollments =
              household[:hbx_enrollments].select do |hbx_enrollment|
                enrollment_criteria(
                  hbx_enrollment,
                  TimeKeeper.date_of_record.year
                )
              end.presence
            household[:hbx_enrollments] =
              perspective_enrollments || current_enrollments
          end
          family_hash
        end

        def validate_payload(payload)
          result =
            ::AcaEntities::Contracts::Families::FamilyContract.new.call(payload)
          return Failure('Unable to validate payload') unless result.success?

          Success(result.to_h)
        end

        def create_entity(values)
          result = AcaEntities::Families::Family.new(values)

          Success(result.to_h)
        end
      end
    end
  end
end

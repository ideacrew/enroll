# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Notices
      # Create document reminder notice for the family
      class BuildCvPayload
        include Dry::Monads[:do, :result]
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
            family_hash[:min_verification_due_date] = family.eligibility_determination&.outstanding_verification_earliest_due_date
            updated_hash = modify_enrollments_hash(family_hash, family)
            # updated_hash = family_hash
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

        def modify_enrollments_hash(family_hash, family)
          return family_hash unless family.enrollments.present?

          family_hash[:households].each do |household|
            household[:hbx_enrollments] = get_enrollments_from_determination(family).collect do |enrollment|
              transform_hbx_enrollment(enrollment)
            end
          end
          family_hash
        end

        def transform_hbx_enrollment(enrollment)
          ::Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment.new.call(enrollment).value!
        end

        def get_enrollments_from_determination(family)
          return [] unless family.eligibility_determination
          enrollment_eligibility_states = ['health_product_enrollment_status', 'dental_product_enrollment_status']

          enrollment_gids = family.eligibility_determination.subjects.collect do |subject|
            eligibility_states = subject.eligibility_states.where(:eligibility_item_key.in => enrollment_eligibility_states).to_a

            eligibility_states.reduce([]) do |e_gids, es|
              e_gids + es.evidence_states.collect{|evidence_state| evidence_state.meta[:enrollment_gid]}
            end
          end.flatten.compact

          enrollment_gids.uniq.collect{|enrollment_gid| GlobalID::Locator.locate(enrollment_gid)}
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

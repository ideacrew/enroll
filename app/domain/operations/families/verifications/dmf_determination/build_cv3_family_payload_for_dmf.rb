# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module Verifications
      module DmfDetermination
        # operation to build cv3 family to publish to fdsh
        class BuildCv3FamilyPayloadForDmf
          include Dry::Monads[:result, :do]
          include ::Operations::Transmittable::TransmittableUtils

          # @return [ Cv3Family ] Job successfully completed
          def call(family, transmittable_params)
            @job = transmittable_params[:job]
            @transmission = transmittable_params[:transmission]
            @transaction = transmittable_params[:transaction]
            @family = family

            cv3_family = yield build_cv3_family
            valid_cv3_family = yield validate_cv3_family(cv3_family)

            yield validate_all_family_members(valid_cv3_family)
            result = yield confirm_transmittable_payload(cv3_family)

            Success(result)
          end

          private

          def build_cv3_family
            cv3_family = Operations::Transformers::FamilyTo::Cv3Family.new.call(@family)
            return handle_dmf_failure("Unable to transform family into cv3_family: #{cv3_family.failure}", :build_cv3_family) if cv3_family.failure?

            cv3_family
          end

          def validate_cv3_family(cv3_family)
            valid_cv3_family = AcaEntities::Operations::CreateFamily.new.call(cv3_family)
            return handle_dmf_failure("Invalid cv3 family: #{valid_cv3_family.failure}", :validate_cv3_family) if valid_cv3_family.failure?

            valid_cv3_family
          end

          def validate_all_family_members(aca_family)
            invalid_persons = aca_family.family_members.map do |aca_member|
              family_member = @family.family_members.detect { |fm| fm.hbx_id == aca_member.hbx_id }

              # check if member does not have an enrollment
              unless member_eligible?(aca_member)
                vh_message = "Family Member with hbx_id #{aca_member.hbx_id} does not have a valid enrollment"
                update_verification_type_histories(vh_message, [family_member])
                next vh_message
              end

              # check if member is valid (valid_ssn, etc.)
              valid_member = Operations::Fdsh::PayloadEligibility::CheckPersonEligibilityRules.new.call(aca_member.person, :alive_status)
              next if valid_member.success?

              vh_message = "Family Member with hbx_id #{aca_member.hbx_id} is not valid: #{valid_member.failure}"
              update_verification_type_histories(vh_message, [family_member])
              vh_message
            end.compact

            # invalid_persons.size == family_members.size indicates no family members were valid
            return Success(aca_family) unless invalid_persons.size == aca_family.family_members.size

            message = "DMF Determination not sent: no family members are eligible"
            # 'false' as third param prevent updating verification histories -> have already been updated
            handle_dmf_failure(message, :build_cv3_family, update_histories: false)
          end

          def member_eligible?(family_member)
            # first check if eligibility_determination has family member as a subject
            subjects = @family.eligibility_determination.subjects
            subject = subjects.detect { |sub| sub.hbx_id == family_member.hbx_id }
            return false unless subject.present?

            # then check if subject has any of the valid eligibility states
            item_keys = ['health_product_enrollment_status', 'dental_product_enrollment_status']
            states = subject&.eligibility_states&.select { |state| item_keys.include?(state.eligibility_item_key) }
            return false unless states.present?

            # last check if valid eligibility states have is_eligible as true
            states.any?(&:is_eligible?)
          end

          def confirm_transmittable_payload(cv3_family)
            payload = { family_hash: cv3_family.to_h, job_id: @job.job_id }

            @transaction.json_payload = payload
            @transaction.save

            if @transaction.json_payload
              Success(payload)
            else
              handle_dmf_failure("Unable to save transaction with payload: #{payload}", :build_cv3_family)
            end
          end

          def transmittable_error_params
            {
              transmission: @transmission,
              transaction: @transaction
            }
          end

          def handle_dmf_failure(message, state, update_histories: true)
            update_verification_type_histories(message) if update_histories

            add_errors(state, message, transmittable_error_params)
            status_result = update_status(message, :failed, transmittable_error_params)
            return status_result if status_result.failure?

            Failure(message)
          end

          def update_verification_type_histories(message, family_members = @family.family_members)
            family_members.each do |member|
              alive_status_verification = member&.person&.alive_status
              next unless alive_status_verification
              alive_status_verification.add_type_history_element(action: "DMF Determination Request Failure", modifier: "System", update_reason: message)
            end
          end
        end
      end
    end
  end
end

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
            result = yield confirm_transmittable_payload(valid_cv3_family)

            Success(result)
          end

          private

          def build_cv3_family
            result = Operations::Transformers::FamilyTo::Cv3Family.new.call(@family)
            return handle_dmf_failure("Unable to transform family into cv3_family: #{result.failure}", :build_cv3_family) if result.failure?

            result
          end

          def validate_cv3_family(cv3_family)
            result = AcaEntities::Operations::CreateFamily.new.call(cv3_family)
            return handle_dmf_failure("Invalid cv3 family: #{result.failure}", :validate_cv3_family) if result.failure?

            result
          end

          def validate_all_family_members(family_entity)
            family_members = @family.family_members
            entity_subjects = family_entity.eligibility_determination.subjects

            members_data = family_entity.family_members.collect do |member_entity|
              family_member = family_members.detect { |fm| fm.hbx_id == member_entity.hbx_id }
              entity_subject = entity_subjects.collect{|_k,v| v if v[:hbx_id] == member_entity.hbx_id }.flatten.compact.first

              result = Operations::Fdsh::PayloadEligibility::CheckDeterminationSubjectEligibilityRules.new.call(entity_subject, :alive_status)

              if result.success?
                {member_entity.hbx_id => {'status' => true, 'error' => :no_errors}}
              else
                error = result.failure
                person = family_member.person
                message = "Family Member is not eligible for DMF Determination due to errors: #{error}"
                add_verification_history(person, "DMF_Request_Failed", message)
                {member_entity.hbx_id => {'status' => false, 'error' => result.failure}}
              end
            end.compact

            member_status = members_data.collect { |hash| hash.collect{|_k,v|  v["status"]} }.flatten.compact

            if member_status.all?(false)
              message = "DMF Determination not sent: no family members are eligible"
              handle_dmf_failure(message, :build_cv3_family, update_histories: false)
            else
              Success(family_entity)
            end
          end

          def confirm_transmittable_payload(valid_cv3_family)
            payload = { family_hash: valid_cv3_family.to_h, job_id: @job.job_id }

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
              add_verification_history(member.person, "DMF_Request_Failed", message)
            end
          end

          def add_verification_history(person, action, update_reason)
            alive_status_verification = person.verification_types.alive_status_type.first
            return unless alive_status_verification
            alive_status_verification.add_type_history_element(action: action, modifier: "System", update_reason: update_reason)
          end
        end
      end
    end
  end
end

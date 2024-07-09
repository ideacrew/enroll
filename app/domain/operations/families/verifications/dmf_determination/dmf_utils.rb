# frozen_string_literal: true

module Operations
  module Families
    module Verifications
      module DmfDetermination
        # this util class contains helper methods used both during the DMF call and writing DMF-related reports
        module DmfUtils
          VALID_ELIGIBLITY_STATES = [
            'health_product_enrollment_status',
            'dental_product_enrollment_status'
          ].freeze

          def member_dmf_determination_eligible_enrollments(family_member, family)
            # first check if eligibility_determination has family member as a subject
            subjects = family.eligibility_determination.subjects
            subject = subjects.detect { |sub| sub.hbx_id == family_member.hbx_id }
            return false unless subject.present?

            # then check if subject has any of the valid eligibility states
            states = subject&.eligibility_states&.select { |state| VALID_ELIGIBLITY_STATES.include?(state.eligibility_item_key) }
            return false unless states.present?

            # check if valid eligibility states have is_eligible as true
            return states if states&.any?(&:is_eligible?)
          end

          def extract_enrollment_info(family, hbx_id)
            family.enrollments.where(:'aasm_state'.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES).each do |enrollment|
              # get first active enrollment which includes the hbx_id (person) as a member
              next if enrollment.hbx_enrollment_members.none? { |member| member.hbx_id == hbx_id }

              return [enrollment.hbx_id, enrollment.aasm_state]
            end
          end
        end
      end
    end
  end
end
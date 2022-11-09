# frozen_string_literal: true

module Insured
  # view helper methods for planning shopping page
  module PlanShoppingHelper
    include L10nHelper

    def is_determined_and_not_csr_0?(entity, enrollment)
      return false unless entity && enrollment
      if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
        enrolled_family_member_ids = enrollment.hbx_enrollment_members.map(&:applicant_id)
        csr_op = ::Operations::PremiumCredits::FindCsrValue.new.call({
                                                                       family: enrollment.family,
                                                                       year: enrollment.effective_on.year,
                                                                       family_member_ids: enrolled_family_member_ids
                                                                     })

        return false unless csr_op.success?

        valid_csr_eligibility_kind = csr_op.value!
      else
        valid_csr_eligibility_kind = entity.valid_csr_kind(enrollment)
      end

      (EligibilityDetermination::CSR_KINDS.include? valid_csr_eligibility_kind.to_s) && (valid_csr_eligibility_kind.to_s != 'csr_0')
    end
  end
end
# frozen_string_literal: true

module HbxEnrollments
# UpdateMthhAptcValuesOnEnrollment is an interactor that updates the aptc values on an enrollment
  class UpdateMthhAptcValuesOnEnrollment
    include Interactor
    include FloatHelper

    before do
      context.fail!(message: "enrollment is required") unless context.enrollment.present?
      context.fail!(message: "elected_aptc_pct is required") unless context.elected_aptc_pct.present?
      context.fail!(message: "new_effective_date is required") unless context.new_effective_date.present?
    end

    # Context Requires:
    # - enrollment
    # - elected_aptc_pct
    # - exclude_enrollments_list
    # - new_effective_date
    def call
      result = ::Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: enrollment, effective_on: new_effective_date, exclude_enrollments_list: exclude_enrollments_list })
      context.fail!(message: result.failure) unless result.success?

      aggregate_aptc_amount = result.value!
      ehb_premium = enrollment.total_ehb_premium

      applied_aptc_amount = float_fix([(aggregate_aptc_amount * elected_aptc_pct), ehb_premium].min)

      enrollment.update_attributes(elected_aptc_pct: elected_aptc_pct, applied_aptc_amount: applied_aptc_amount, aggregate_aptc_amount: aggregate_aptc_amount, ehb_premium: ehb_premium)
    end

    private

    def enrollment
      @enrollment ||= context.enrollment
    end

    def elected_aptc_pct
      @elected_aptc_pct ||= context.elected_aptc_pct
    end

    def exclude_enrollments_list
      context.exclude_enrollments_list || []
    end

    def new_effective_date
      context.new_effective_date
    end
  end
end
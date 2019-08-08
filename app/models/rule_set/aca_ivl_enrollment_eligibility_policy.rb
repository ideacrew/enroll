# frozen_string_literal: true

module RuleSet
  class AcaIvlEnrollmentEligibilityPolicy
    include ::BenefitMarkets::BusinessRulesEngine

    VALID_MARKET_KIND = 'individual'
    APTC_INELIGIBLE_ENROLLMENT_STATES = ::HbxEnrollment::CANCELED_STATUSES + ::HbxEnrollment::TERMINATED_STATUSES
    APTC_ELIGIBLE_ENROLLMENT_STATES = ::HbxEnrollment.aasm.states.map(&:name).map(&:to_s) - APTC_INELIGIBLE_ENROLLMENT_STATES

    rule :any_member_aptc_eligible,
         validate: lambda { |enrollment|
           fac_obj = ::Factories::IvlEligibilityFactory.new(enrollment.id)
           fac_obj.any_member_aptc_eligible?
         },
         success: ->(_enrollment){ 'validated successfully' },
         fail: ->(_enrollment){ 'None of the shopping members are eligible for APTC' }

    rule :market_kind_eligiblity,
         validate: ->(enrollment){ enrollment.kind == VALID_MARKET_KIND },
         success: ->(_enrollment) { 'validated successfully' },
         fail: ->(enrollment) {"Market Kind of given enrollment is #{enrollment.kind} and not #{VALID_MARKET_KIND}"}

    rule :any_member_csr_ineligible,
         validate: lambda { |enrollment|
           fac_obj = ::Factories::IvlEligibilityFactory.new(enrollment.id)
           !fac_obj.any_member_csr_ineligible?
         },
         success: ->(_enrollment){ 'validated successfully' },
         fail: ->(_enrollment){ 'One of the shopping members are ineligible for CSR' }

    rule :valid_state,
         validate: ->(enrollment){ APTC_INELIGIBLE_ENROLLMENT_STATES.exclude?(enrollment.aasm_state) },
         success: ->(_enrollment) { 'validated successfully' },
         fail: ->(enrollment) { "Aasm state of given enrollment is #{enrollment.aasm_state} which is an invalid state" }

    business_policy :apply_aptc,
                    rules: [:market_kind_eligiblity,
                            :any_member_aptc_eligible]

    business_policy :apply_csr,
                    rules: [:any_member_csr_ineligible]

    business_policy :edit_aptc,
                    rules: [:valid_state]

    def business_policies_for(enrollment, event_name)
      return unless enrollment.is_a?(::HbxEnrollment)

      case event_name
      when :apply_aptc
        business_policies[:apply_aptc]
      when :apply_csr
        business_policies[:apply_csr]
      when :edit_aptc_on_enrollment
        business_policies[:edit_aptc]
      end
    end
  end
end

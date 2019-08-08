# frozen_string_literal: true

module RuleSet
  class AcaIvlEnrollmentEligibilityPolicy
    include ::BenefitMarkets::BusinessRulesEngine

    VALID_MARKET_KIND = 'individual'

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


    business_policy :apply_aptc,
                    rules: [:market_kind_eligiblity,
                            :any_member_aptc_eligible]

    business_policy :apply_csr,
                    rules: [:any_member_csr_ineligible]

    def business_policies_for(enrollment, event_name)
      return unless enrollment.is_a?(::HbxEnrollment)

      case event_name
      when :apply_aptc
        business_policies[:apply_aptc]
      when :apply_csr
        business_policies[:apply_csr]
      end
    end
  end
end

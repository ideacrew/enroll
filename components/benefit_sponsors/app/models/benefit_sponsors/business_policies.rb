# frozen_string_literal: true

module BenefitSponsors
  module BusinessPolicies
    module PolicyContainer
      extend Dry::Container::Mixin

      register "fehb_benefit_sponsorship_policy" do
        BenefitSponsors::BusinessPolicies::YesBusinessPolicy.new
      end

      register "aca_shop_benefit_sponsorship_policy" do
        BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipPolicy.new
      end

      register "aca_shop_benefit_application_eligibility_policy" do
        BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
      end

      register "fehb_benefit_application_eligibility_policy" do
        BenefitSponsors::BenefitApplications::FehbApplicationEligibilityPolicy.new
      end

      register "aca_shop_benefit_application_enrollment_eligibility_policy" do
        BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
      end

      register "fehb_benefit_application_enrollment_eligibility_policy" do
        BenefitSponsors::BusinessPolicies::YesBusinessPolicy.new
      end
    end

    class PolicyResolver
      def self.benefit_sponsorship_policy_for(benefit_sponsorship, business_policy_name)
        container_key = benefit_sponsorship.market_kind.to_s + "_benefit_sponsorship_policy"
        sponsor_policy = PolicyContainer[container_key]
        sponsor_policy.business_policies_for(benefit_sponsorship, business_policy_name)
      end

      def self.benefit_application_eligibility_policy
        PolicyContainer["aca_shop_benefit_application_eligibility_policy"]
      end

      singleton_class.deprecate :benefit_application_eligibility_policy

      def self.benefit_application_eligibility_policy_for(benefit_application, business_policy_name)
        container_key = benefit_application.benefit_sponsorship.market_kind.to_s + "_benefit_application_eligibility_policy"
        sponsor_policy = PolicyContainer[container_key]
        sponsor_policy.business_policies_for(benefit_application, business_policy_name)
      end

      def self.benefit_application_enrollment_eligibility_policy
        PolicyContainer["aca_shop_benefit_application_enrollment_eligibility_policy"]
      end

      singleton_class.deprecate :benefit_application_enrollment_eligibility_policy

      def self.benefit_application_enrollment_eligibility_policy_for(benefit_application, business_policy_name)
        container_key = benefit_application.benefit_sponsorship.market_kind.to_s + "_benefit_application_enrollment_eligibility_policy"
        sponsor_policy = PolicyContainer[container_key]
        sponsor_policy.business_policies_for(benefit_application, business_policy_name)
      end
    end

    Injector = Dry::AutoInject(PolicyContainer)
  end
end

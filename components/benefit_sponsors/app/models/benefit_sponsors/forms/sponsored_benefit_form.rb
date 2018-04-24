module BenefitSponsors
  module Forms
    class SponsoredBenefitForm
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :kind, String

      attribute :sponsor_contribution, SponsorContributionForm
      attribute :benefit_products, Array[BenefitProductForm]
      attribute :eligibility_policies, Array[EligibilityPolicyForm]
      attribute :pricing_determinations, Array[PricingDeterminationForm]

    end
  end
end

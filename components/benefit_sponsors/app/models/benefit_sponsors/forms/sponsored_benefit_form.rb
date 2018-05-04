module BenefitSponsors
  module Forms
    class SponsoredBenefitForm
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :kind, String
      attribute :plan_option_kind, String

      attribute :products, Array[BenefitProductForm]
      attribute :reference_product, BenefitProductForm

      attribute :sponsor_contribution, SponsorContributionForm
      attribute :pricing_determinations, Array[PricingDeterminationForm]

      def self.for_new
        kinds.collect do |kind|
          form = self.new(kind: kind)
          form.sponsor_contribution = SponsorContributionForm.for_new
          form
        end
      end

      def self.kinds
        %w(health)
      end
    end
  end
end

module BenefitSponsors
  module Forms
    class SponsoredBenefitForm
      
      include Virtus.model
      include ActiveModel::Model

      attribute :kind, String
      attribute :plan_option_kind, String
      attribute :carrier_for_elected_plan, String
      attribute :metal_level_for_elected_plan, String

      attribute :products, Array[BenefitProductForm]
      attribute :reference_product, BenefitProductForm

      attribute :sponsor_contribution, SponsorContributionForm
      attribute :pricing_determinations, Array[PricingDeterminationForm]

      attr_accessor :sponsor_contribution

      def sponsor_contribution_attributes=(attributes)
        @sponsor_contribution ||= []
        attributes.each do |i, sponsor_contribution_attributes|
          @sponsor_contribution.push(SponsorContributionForm.new(sponsor_contribution_attributes))
        end
      end

      def self.for_new
        kinds.collect do |kind|
          form = self.new(kind: kind)
          form.sponsor_contribution = SponsorContributionForm.for_new
          form
        end
      end

      def self.kinds
        %w(health)
        # get kinds from catalog based on products/product packages
      end
    end
  end
end

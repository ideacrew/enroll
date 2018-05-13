module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_package, 
                  class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      field :product_package_kind, type: Symbol

      # field :plan_option_choice , type: String # carrier id / metal level

      embeds_one  :sponsor_contribution, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"
      embeds_many :pricing_determinations, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

      delegate :benefit_sponsor_catalog, to: :benefit_package

      def latest_pricing_determination
        pricing_determinations.sort_by(&:created_at).last
      end

      def renew(new_product_package)
        #   map products
        #   map reference product
        #   build sponsor contribution model
        #   DO NOT COPY pricing determinations        
      end

      # plan_option_kind & plan_option_choice
      # Gold/silver/Carefirst/Kaiser
      def plan_option_choice=(choice)
        return if choice.blank?
        self.products = benefit_sponsor_catalog.products_for(plan_option_kind, choice)
      end

      def reference_plan_id=(product_id)
        self.reference_product = products.where(id: product_id).first
      end

      def sponsor_contributions=(sponsor_contribution_attrs)
        build_sponsor_contribution(sponsor_contribution_attrs)
      end
    end
  end
end
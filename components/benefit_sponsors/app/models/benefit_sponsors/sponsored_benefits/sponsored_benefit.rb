module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_package, 
                  class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      field :product_option_choice, type: String # carrier id / metal level
      field :product_package_kind, type: Symbol

      # scope :by_metal_level_kind

      # scope :by_issuer

      embeds_one  :sponsor_contribution, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"
      embeds_many :pricing_determinations, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

      delegate :benefit_sponsor_catalog, to: :benefit_package
      delegate :rate_schedule_date, to: :benefit_package

      def latest_pricing_determination
        pricing_determinations.sort_by(&:created_at).last
      end

      def renew(new_product_package)
        #   map products
        #   map reference product
        #   build sponsor contribution model
        #   DO NOT COPY pricing determinations        
      end

      def product_option_choice=(product_option_choice)
        product_package = benefit_sponsor_catalog.product_packages.by_kind(product_package_kind).first
        self.products = benefit_sponsor_catalog.products_for(product_package, product_option_choice)
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

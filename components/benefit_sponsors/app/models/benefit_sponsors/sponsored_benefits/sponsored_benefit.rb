module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_package, 
                  class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      field :product_package_kind,  type: Symbol
      field :product_option_choice, type: String # carrier id / metal level

      embeds_one  :reference_product, 
                  class_name: "::BenefitMarkets::Products::HealthProducts::HealthProduct"

      embeds_one  :sponsor_contribution, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"

      embeds_many :pricing_determinations, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

      delegate :rate_schedule_date, to: :benefit_package

      delegate :contribution_model, to: :product_package, allow_nil: true
      delegate :pricing_model, to: :product_package, allow_nil: true
      delegate :pricing_calculator, to: :product_package, allow_nil: true
      delegate :contribution_calculator, to: :product_package, allow_nil: true

      validate :product_package_exists
      validates_presence_of :sponsor_contribution

      def product_package_exists
        if product_package.blank?
          self.errors.add(:base => "Unable to find mappable product package")
        end
      end

      def product_kind
        self.class.name.demodulize.split('SponsoredBenefit')[0].downcase.to_sym
      end

      # Don't remove this. Added it to get around mass assignment
      def kind=(kind)
        # do nothing
      end

      def product_package
        return @product_package if defined? @product_package
        @product_package = benefit_sponsor_catalog.product_packages.by_package_kind(product_package_kind).by_product_kind(product_kind)[0]
      end

      def latest_pricing_determination
        pricing_determinations.sort_by(&:created_at).last
      end

      def renew(new_benefit_package)
        new_benefit_sponsor_catalog = new_benefit_package.benefit_sponsor_catalog
        new_product_package = new_benefit_sponsor_catalog.product_package_for(self)

        if new_product_package.present? && reference_product.present?
          if reference_product.renewal_product.present? && new_product_package.active_products.include?(reference_product.renewal_product)
            self.class.new(
              product_package_kind: product_package_kind,
              product_option_choice: product_option_choice,
              reference_product: reference_product.renewal_product,
              sponsor_contribution: sponsor_contribution.renew(new_product_package),
              pricing_determinations: renew_pricing_determinations(new_product_package)
            )
          end
        end
      end

      def renew_pricing_determinations(new_product_package)
      end

      def benefit_sponsor_catalog
        return if benefit_package.blank?
        benefit_package.benefit_sponsor_catalog
      end

      def reference_plan_id=(product_id)
        self.reference_product = product_package.products.where(id: product_id).first
      end

      def sponsor_contribution_attributes=(sponsor_contribution_attrs)
        # build_sponsor_contribution(sponsor_contribution_attrs)
      end
    end
  end
end

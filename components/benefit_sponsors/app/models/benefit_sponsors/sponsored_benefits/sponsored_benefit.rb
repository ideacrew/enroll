module BenefitSponsors
  class SponsoredBenefits::SponsoredBenefit
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_package,
                class_name: "::BenefitSponsors::BenefitPackages::BenefitPackage",
                inverse_of: :sponsored_benefits

    field :product_package_id,    type: BSON::ObjectId
    field :reference_product_id,  type: BSON::ObjectId

    # field :product_kind,          type: Symbol
    # field :product_package_kind,  type: Symbol
    # field :product_option_choice, type: String # carrier id / metal level

    # FIXME -- This must reference a Product available in the BenefitSponsorCatalog
    # belongs_to :reference_product, class_name: "::BenefitMarkets::Products::Product", inverse_of: nil

    embeds_one  :sponsor_contribution,
                class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"

    embeds_many :pricing_determinations,
                class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

    delegate :contribution_model,         to: :product_package, allow_nil: true
    delegate :pricing_model,              to: :product_package, allow_nil: true
    delegate :pricing_calculator,         to: :product_package, allow_nil: true
    delegate :contribution_calculator,    to: :product_package, allow_nil: true
    delegate :recorded_rating_area,       to: :benefit_package
    delegate :recorded_service_area_ids,  to: :benefit_package
    delegate :recorded_sic_code,          to: :benefit_package
    delegate :rate_schedule_date,         to: :benefit_package
    delegate :benefit_sponsor_catalog,    to: :benefit_package
    delegate :benefit_sponsorship,        to: :benefit_package

    validates_presence_of :product_package, :sponsor_contribution, :pricing_determinations
    # validate :product_package_exists
    #      validates_presence_of :sponsor_contribution

    # def product_package_exists
    #   if product_package.blank?
    #     self.errors.add(:base => "Unable to find mappable product package")
    #   end
    # end


#### FIXME - these attributes should be set when BenefitSponsorCatalog product package is assigned
    def product_package_present?
      product_package_id.present?
    end

    def product_package_kind=(new_product_package_kind)
      @product_package_kind = new_product_package_kind
    end

    def product_package_kind
      @product_package_kind
      # product_package.package_kind if product_package.present?
    end

    def product_kind
      product_package.product_kind if product_package.present?
    end

#####

    # Don't remove this. Added it to get around mass assignment
    def kind=(kind)
      # do nothing
    end

    def single_plan_type?
      product_package_kind == :single_product
    end


    # FIXME Remove date argument
    def products(coverage_date = nil)
      return [reference_product] if product_package_kind == :single_product
      product_package.products.present? ? product_package.products : []
    end

    # FIXME Deprecate
    def lookup_package_products(coverage_date)
      products

      # return [reference_product] if product_package_kind == :single_product
      # product_package.products
      # BenefitMarkets::Products::Product.by_coverage_date(product_package.products_for_plan_option_choice(product_option_choice).by_service_areas(recorded_service_area_ids), coverage_date)
    end

    def product_package=(new_product_package)
      if new_product_package.nil?
        write_attribute(:product_package_id, nil)
      else
        raise ArgumentError.new("expected ProductPackage") unless new_product_package.is_a? ::BenefitMarkets::Products::ProductPackage
        write_attribute(:product_package_id, new_product_package._id)
      end
      @product_package = new_product_package
    end

    def product_package
      return nil if product_package_id.nil?
      return @product_package if defined? @product_package
      @product_package = benefit_sponsor_catalog.product_package_for(self)
    end

    def reference_product=(new_reference_product)
      if new_reference_product.nil?
        write_attribute(:reference_product_id, nil)
      else
        raise ArgumentError.new("expected ReferenceProduct") unless new_reference_product.is_a? ::BenefitMarkets::Products::ProductPackage
        write_attribute(:reference_product_id, new_reference_product._id)
      end
      @reference_product = new_reference_product
    end

    def reference_product
      return nil if reference_product_id.nil?
      return @reference_product if defined? @reference_product
      @reference_product = products.detect { |product| product._id == reference_product_id }
    end

    # FIX this stub
    ## Deprecate for reference_product getter/setter above
    def reference_product_id=(reference_product_id)
      write_attribute(:reference_product_id, reference_product_id)
    end

    ## Deprecate for reference_product getter/setter above
    def reference_plan_id=(product_id)
      reference_product_id = product_id
    end

    def issuers_offered
      product_package.present? ? product_package.products.pluck(:issuer_profile_id).uniq : []
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
            sponsor_contribution: sponsor_contribution.renew(new_product_package)
            # pricing_determinations: renew_pricing_determinations(new_product_package)
          )
        end
      end
    end

    def renew_pricing_determinations(new_product_package)
    end

    def sponsor_contribution_attributes=(sponsor_contribution_attrs)
      # build_sponsor_contribution(sponsor_contribution_attrs)
    end
  end
end

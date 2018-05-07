# Support product import from SERFF, CSV templates, etc

# Effective dates during which sponsor may purchase this product at this price
## DC SHOP Health   - annual product changes & quarterly rate changes
## CCA SHOP Health  - annual product changes & quarterly rate changes
## DC IVL Health    - annual product & rate changes
## Medicare         - annual product & semiannual rate changes

module BenefitMarkets
  class Products::Product
    include Mongoid::Document
    include Mongoid::Timestamps

    field :benefit_market_kind,   type: Symbol

    # Time period during which Sponsor may include this product in benefit application
    field :application_period,    type: Range   # => Mon, 01 Jan 2018..Mon, 31 Dec 2018

    field :hbx_id,                type: String
    field :issuer_profile_urn,    type: String
    field :title,                 type: String
    field :description,           type: String
    field :product_package_kinds, type: Array, default: []
    field :issuer_profile_id,     type: BSON::ObjectId

    field :active_year, type: Integer
    field :coverage_kind, type: String
    field :metal_level, type: String

    field :hios_id, type: String
    field :hios_base_id, type: String
    field :csr_variant_id, type: String

    field :abbrev, type: String
    field :provider, type: String
    field :ehb, type: Float, default: 0.0

    field :renewal_plan_id, type: BSON::ObjectId
    field :cat_age_off_renewal_plan_id, type: BSON::ObjectId
    field :is_standard_plan, type: Boolean, default: false

    field :minimum_age, type: Integer, default: 0
    field :maximum_age, type: Integer, default: 120

    # More Attributes from qhp
    field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
    field :deductible, type: String # Deductible
    field :family_deductible, type: String
    field :network_information, type: String
    field :nationwide, type: Boolean # Nationwide
    field :dc_in_network, type: Boolean # DC In-Network or not

    # Fields for provider direcotry and rx formulary url
    field :provider_directory_url, type: String
    field :rx_formulary_url, type: String


    belongs_to  :service_area,
                counter_cache: true,
                class_name: "BenefitMarkets::Locations::ServiceArea"

    embeds_one  :sbc_document, :class_name => "Document", as: :documentable
    embeds_many :premium_tables,
                class_name: "BenefitMarkets::Products::PremiumTable", cascade_callbacks: true


    validates_presence_of :benefit_market_kind, :title, :premium_tables #:hbx_id, :issuer_profile_urn, :service_area, :application_period


    validates :benefit_market_kind,
              presence: true,
              inclusion: {in: BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind"}


    index({ hbx_id: 1 })
    index({ benefit_market_kind: 1, "application_period.min" => 1, "application_period.max" => 1 })
    index({ "premium_tables.rating_area" => 1, 
            "premium_tables.effective_period.min" => 1, 
            "premium_tables.effective_period.max" => 1 },
            {name: "premium_tables"})

    scope :by_product_package,    ->(product_package) {
      # product_package.benefit_market_kind
      # product_package.application_period
      # product_package.product_kind
      # product_package.kind

      where(:"product_package_kinds" => product_package.product_kind)
    }

    scope :by_service_area,       ->(service_area){ where(service_area: service_area) }

    scope :aca_shop_market,       ->{ where(benefit_market_kind: :aca_shop) }
    scope :aca_individual_market, ->{ where(benefit_market_kind: :aca_individual) }

    scope :by_application_date,   ->(date){ where(:"application_period.min".gte => date, :"application_period.max".lte => date) }

    def issuer_profile
      return @issuer_profile if is_defined?(@issuer_profile)
      @issuer_profile = ::BenefitSponsors::Organizations::IssuerProfile.find(self.issuer_profile_id)
    end

    def issuer_profile=(new_issuer_profile)
      write_attribute(:issuer_profile_id, new_issuer_profile.id)
      @issuer_profile = new_issuer_profile
    end

    def premium_table_effective_on(effective_date)
      premium_tables.detect { |premium_table| premium_table.effective_period.cover?(effective_date) }
    end

    # Add premium table, covering extended time period, to existing product.  Used for products that
    # have periodic rate changes, such as ACA SHOP products that are updated quarterly.  
    def add_premium_table(new_premium_table)
      raise InvalidEffectivePeriodError unless is_valid_premium_table_effective_period?(new_premium_table)

      if premium_table_effective_on(new_premium_table.effective_period.min).present? || 
          premium_table_effective_on(new_premium_table.effective_period.max).present?
        raise DuplicatePremiumTableError, "effective_period may not overlap existing premium_table"
      else
        premium_tables << new_premium_table
      end
      self
    end

    def update_premium_table(updated_premium_table)
      raise InvalidEffectivePeriodError unless is_valid_premium_table_effective_period?(updated_premium_table)

      drop_premium_table(premium_table_effective_on(updated_premium_table.effective_period.min))
      add_premium_table(updated_premium_table)
    end

    def drop_premium_table(premium_table)
      premium_tables.delete(premium_table) unless premium_table.blank?
    end

    def is_valid_premium_table_effective_period?(compare_premium_table)
      return false unless application_period.present? && compare_premium_table.effective_period.present?

      if application_period.cover?(compare_premium_table.effective_period.min) && 
          application_period.cover?(compare_premium_table.effective_period.max)
        true
      else
        false
      end
    end

    def add_product_package(new_product_package)
      product_packages.push(new_product_package).uniq!
      product_packages
    end

    def drop_product_package(product_package)
      product_packages.delete(product_package) { "not found" }
    end

  end

end

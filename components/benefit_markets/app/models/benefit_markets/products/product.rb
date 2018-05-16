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
    field :title,                 type: String
    field :description,           type: String, default: ""
    field :issuer_profile_id,     type: BSON::ObjectId
    field :product_package_kinds, type: Array, default: []
    field :_type,                 type: String
    field :premium_ages,          type: Range


    belongs_to  :service_area,
                counter_cache: true,
                class_name: "BenefitMarkets::Locations::ServiceArea"

    embeds_many :premium_tables,
                class_name: "BenefitMarkets::Products::PremiumTable"

    # validates_presence_of :hbx_id
    validates_presence_of :application_period, :benefit_market_kind,  :title,
                          :premium_tables, :service_area


    validates :benefit_market_kind,
              presence: true,
              inclusion: {in: BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind"}


    index({ hbx_id: 1 })
    index({ "benefit_market_kind" => 1, 
            "application_period.min" => 1, 
            "application_period.max" => 1, 
            "product_package_kinds" => 1, 
            "_type" => 1 },
            {name: "product_package"})

    index({ "premium_tables.rating_area" => 1, 
            "premium_tables.effective_period.min" => 1, 
            "premium_tables.effective_period.max" => 1 },
            {name: "premium_tables"})

    scope :by_product_package,    ->(product_package) { where(
                :"benefit_market_kind"          => product_package.benefit_market_kind,
                :"application_period.min"       => product_package.application_period.min,
                :"application_period.max"       => product_package.application_period.max,
                :"product_package_kinds"        => /#{product_package.kind}/,
                :"_type"                        => /#{product_package.product_kind}/i
      )
    }

    scope :by_service_area,       ->(service_area){ where(service_area: service_area) }

    scope :aca_shop_market,       ->{ where(benefit_market_kind: :aca_shop) }
    scope :aca_individual_market, ->{ where(benefit_market_kind: :aca_individual) }

    scope :by_application_date,   ->(date){ where(:"application_period.min".gte => date, :"application_period.max".lte => date) }

    scope :by_metal_level_kind,   ->(metal_level){ where(metal_level_kind: /#{metal_level}/i) }
    scope :by_issuer_profile,     ->(issuer_profile){ where(issuer_profile_id: issuer_profile.id) }
   
    def issuer_profile
      return @issuer_profile if defined?(@issuer_profile)
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

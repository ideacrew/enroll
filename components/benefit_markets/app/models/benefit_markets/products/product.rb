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

    # belongs_to  :issuer_profile, 
    #             class_name: "::BenefitSponsors::Organizations::IssuerProfile"
    
    belongs_to  :service_area,
                counter_cache: true,
                class_name: "BenefitMarkets::Locations::ServiceArea"

    embeds_one  :issuer_profile

    embeds_many :premium_tables,
                class_name: "BenefitMarkets::Products::PremiumTable"


    validates_presence_of :hbx_id, :benefit_market_kind, :application_period, :title,
                          :issuer_profile_urn, :premium_tables, :service_area


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
    }

    scope :by_service_area,       ->(service_area){ where(service_area: service_area) }

    scope :aca_shop_market,       ->{ where(benefit_market_kind: :aca_shop) }
    scope :aca_individual_market, ->{ where(benefit_market_kind: :aca_individual) }

    scope :by_application_date,   ->(date){ where(:"application_period.min".gte => date, :"application_period.max".lte => date) }

    # TODO: Change this to API call
    def issuer_profile
      # return unless issuer_profile_urn.present?
      IssuerStub.new
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

  class IssuerStub
    attr_reader :name, :urn, :hbx_carrier_id, :fein, :issuer_hios_id, :benefit_market_kinds, 
                :product_kinds, :issuer_state

    def initialize
      @name                 = "SafeCo"
      @urn                  = "urn:openhbx:terms:v1:"
      @hbx_carrier_id       = "123456789"
      @fein                 = "555555555"
      @issuer_hios_id       = "hios-123"
      @benefit_market_kinds = [:aca_shop]
      @product_kinds        = [:health]  # => [:health, :dental]
      @issuer_state         = "MD"
    end

    def as_document
    end

    def validated?
      true
    end

    def flagged_for_destroy?
      false
    end
  end

  class DuplicatePremiumTableError < StandardError; end
  class InvalidEffectivePeriodError < StandardError; end
end

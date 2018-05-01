# Support product import from SERFF, CSV templates, etc

## Product premium periods
# DC & MA SHOP Health: Q1, Q2, Q3, Q4
# DC Dental: annual
# GIC Medicare: Jan-June, July-Dec
# DC & MA IVL: annual

# Effective dates during which sponsor may purchase this product at this price
## DC SHOP Health   - annual product changes & quarterly rate changes
## CCA SHOP Health  - annual product changes & quarterly rate changes
## DC IVL Health    - annual product & rate changes
## Medicare         - annual product & semiannual rate changes

module BenefitMarkets
  module Products
    class Product
      include Mongoid::Document
      include Mongoid::Timestamps

      field :benefit_market_kind, type: Symbol

      # Time period during which Sponsor may include this product in benefit application
      field :application_period,  type: Range   # => Mon, 01 Jan 2018..Mon, 31 Dec 2018

      field :hbx_id,              type: String
      field :issuer_profile_urn,  type: String
      field :title,               type: String
      field :description,         type: String

      belongs_to  :issuer, 
                  class_name: "::IssuerProfile"
                  # class_name: BenefitMarkets.issuer_class.to_s

      embeds_many :premium_tables,
                  class_name: "BenefitMarkets::Products::PremiumTable"


      validates_presence_of :hbx_id, :benefit_market_kind, :application_period, :title
                            # :issuer_urn, :premium_tables


      validates :benefit_market_kind,
                presence: true,
                inclusion: {in: BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind"}


      index({ hbx_id: 1 })
      index({ benefit_market_kind: 1, product_kind: 1, "application_period.min": 1, "application_period.max": 1 })


      scope :aca_shop_market,       ->{ where(benefit_market_kind: :aca_shop) }
      scope :aca_individual_market, ->{ where(benefit_market_kind: :aca_individual) }

      scope :by_application_date,   ->(date){ where(:"application_period.min".gte => date, :"application_period.max".lte => date) }


      # TODO: Change this to API call
      def issuer_profile
        # return unless issuer_profile_urn.present?
        IssuerStub.new
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

    end
  end
end

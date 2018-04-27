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

      KINDS = [:health, :dental]

      field :hbx_id,              type: String
      field :issuer_assigned_id,  type: String
      field :market,              type: Symbol
      field :kind,                type: Symbol
      field :active_period,       type: Range

      field :title,               type: String
      field :description,         type: String

      belongs_to  :issuer

      embeds_many :premium_tables,
                  class_name: "Products::PremiumTable"


      validates :kind,
                presence: true,
                inclusion: {in: KINDS, message: "%{value} is not a valid product kind"}

      validates :market,
                presence: true,
                inclusion: {in: BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind"}


      index({ hbx_id: 1, title: 1 })


    end
  end
end

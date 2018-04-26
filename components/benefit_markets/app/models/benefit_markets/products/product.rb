# Support product import from SERFF, CSV templates, etc
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

      index({ hbx_id: 1, title: 1 })

      embeds_many :premium_tables,
                  class_name: "Products::PremiumTable"


      validates :kind,
                presence: true,
                inclusion: {in: KINDS, message: "%{value} is not a valid product kind"}

      validates :market,
                presence: true,
                inclusion: {in: BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind"}

    end
  end
end

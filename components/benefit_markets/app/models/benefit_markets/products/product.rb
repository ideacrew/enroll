# Support product import from SERFF, CSV templates, etc
module BenefitMarkets
  module Products
    class Product
      include Mongoid::Document
      include Mongoid::Timestamps

      KINDS = [:health, :dental]

      field :hbx_id,  type: String
      field :kind,    type: Symbol
    end
  end
end

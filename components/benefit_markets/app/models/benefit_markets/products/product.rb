module BenefitMarkets
  module Products
    class Product
    include Mongoid::Document
    include Mongoid::Timestamps

    KINDS = [:health, :dental]

    field :hbx_id, type: String





    end
  end
end

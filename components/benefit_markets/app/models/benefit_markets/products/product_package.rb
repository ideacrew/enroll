module BenefitMarkets
  module Products
    class ProductPackage
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id,  type: String
      field :title,   type: String
      field :kind,    type: Symbol

      # Embed, rather than associate, products to avoid issues for sponsors that select member-choice 
      # packages and new issuers/plans arrive midyear
      embeds_many :products, class_name: "BenefitMarkets::Products::Product"


      def product_list_for(product_package_option)
      end




    end
  end
end

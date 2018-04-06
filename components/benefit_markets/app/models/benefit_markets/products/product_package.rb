# ProductPackage provides the composite package for Benefits that may be purchased.  Site 
# exchange Admins (or seed files) define ProductPackage settings.  Benefit Catalog accesses 
# all Products via ProductPackage. 
# ProductPackage functions:
# => Provides filters for benefit display
# => Instantiates a SponsoredBenefit class for inclusion in BenefitPackage
# 
# Product package instance examples
# Cca::Health::OneIssuer
# => benefit_option: one_issuer
# => contribution_model: list_bill_contribution_model
# => price_model: nil
# Cca::Health::MetalLevel
# => contribution_model: list_bill_contribution_model
# => price_model: nil
# Cca::Health::OnePlan
# => contribution_model: cca_composite_contribution_model
# => price_model: composite_price_model
#
# Dc::Health::OneIssuer
# => contribution_model: list_bill_contribution_model
# => price_model: nil
# Dc::Health::MetalLevel
# => contribution_model: list_bill_contribution_model
# => price_model: nil
# Dc::Health::OnePlan
# => contribution_model: list_bill_contribution_model
# => price_model: nil

module BenefitMarkets
  module Products
    class ProductPackage
      include Mongoid::Document
      include Mongoid::Timestamps

      BENEFIT_OPTION_KINDS = [:any, :one_product, :one_issuer, :platinum_level, :gold_level]

      field :reference, type: Symbol # => Issuer, Product, MetalLevel

      field :hbx_id,                  type: String
      field :title,                   type: String
      field :kind,                    type: Symbol
      field :contribution_model_kind, type: Symbol
      field :price_model_kind,        type: Symbol
      field :benefit_option_kind,          type: Symbol
      field :product_list,            type: Array

      belongs_to  :benefit_catalog, class_name: "BenefitMarkets::BenefitCatalog"

      validates_presence_of :title, :kind

      belongs_to :contribution_model 


      def product_list_for(benefit_option)
        # criteria must use:
        # => sponsor's service_area, effective_date
      end

# Premium range



# Deductable range
# POS, HMO, PPO, EPO
# Nationwide, DC Network
# IsStandardPlan

      def sponsored_benefit_for
      end



    end
  end
end

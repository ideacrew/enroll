# BenefitMarket is a marketplace where BenefitSponsors choose benefit products to offer to their members.  Market behaviors and products
# are governed by law, along with rules and policies of the market owner.  ACA Individual market and ACA SHOP market are two example market kinds.
# BenefitMarket owners publish and refresh benefit products on a periodic basis using BenefitCatalogs
module BenefitMarkets
  class BenefitMarket
    include Mongoid::Document
    include Mongoid::Timestamps

    field :site_urn,    type: String
    field :kind,        type: Symbol #, default: :aca_individual  # => :aca_shop
    field :title,       type: String, default: "" # => DC Health Link SHOP Market
    field :description, type: String, default: ""

    belongs_to  :site, class_name: "::BenefitSponsors::Site", inverse_of: nil, optional: true
    has_many    :benefit_market_catalogs, class_name: "BenefitMarkets::BenefitMarketCatalog"
    embeds_one  :configuration, class_name: "BenefitMarkets::Configurations::Configuration"
    # embeds_one :contact_center_setting, class_name: "BenefitMarkets::ContactCenterConfiguration",
                                        # autobuild: true
  end
end
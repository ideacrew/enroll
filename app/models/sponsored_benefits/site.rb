module SponsoredBenefits
  class Site
    include Mongoid::Document
    include Mongoid::Timestamps

    field :site_id, type: Symbol  # For example, :dc, :cca
    field :title,   type: String

    # TODO -- come up with scheme to manage/store these attributes and provide defaults
    field :logo,    type: BSON::Binary
    field :colors,  type: Array

    has_one     :owner_organization,  class_name: "SponsoredBenefits::Organizations:Organization"
    has_many    :benefit_markets,     class_name: "SponsoredBenefits::BenefitMarkets:BenefitMarket"

    has_many    :broker_agencies,     class_name: "SponsoredBenefits::BenefitMarkets:BenefitMarket"
    has_many    :general_agencies,    class_name: "Sponsore dBenefits::BenefitMarkets:BenefitMarket"
    # has_many :families,         class_name: "::Family"

    has_many  :issuers do
      Organizations.where()
    end



    validates_presence_of :site_id

    index({ "site_id" => 1 })


  end
end

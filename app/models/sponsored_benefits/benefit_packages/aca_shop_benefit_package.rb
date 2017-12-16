module SponsoredBenefits
  class BenefitPackages::AcaShopBenefitPackage
    include Mongoid::Document

    belongs_to :packageable, polymorphic: true
  end
end

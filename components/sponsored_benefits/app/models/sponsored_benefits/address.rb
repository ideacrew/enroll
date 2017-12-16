module SponsoredBenefits
  class Address
    include Mongoid::Document
    include Mongoid::Timestamps
    include SponsoredBenefits::Concerns::Address

  end
end

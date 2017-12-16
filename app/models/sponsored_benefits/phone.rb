module SponsoredBenefits
  class Phone
  	include Mongoid::Document
    include Mongoid::Timestamps
    include SponsoredBenefits::Concerns::Phone
  end
end
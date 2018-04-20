module BenefitSponsors
  module Serializers
    class AddressSerializer < ActiveModel::Serializer
      attributes :address_1, :address_2
    end
  end
end

module BenefitSponsors
  module Serializers
    class OfficeLocationSerializer < ActiveModel::Serializer
      attributes :is_primary

      has_one :phone
      has_one :address
    end
  end
end

module BenefitSponsors
  module Serializers
    class ProfileSerializer < ActiveModel::Serializer
      attributes :entity_kind

      has_many :office_locations
    end
  end
end

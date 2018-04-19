module BenefitSponsors
  module Serializers
    class RegistrationSerializer < ActiveModel::Serializer
      has_one :person
      has_one :organization
    end
  end
end

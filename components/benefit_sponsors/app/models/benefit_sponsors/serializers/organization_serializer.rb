module BenefitSponsors
  module Serializers
    class OrganizationSerializer < ActiveModel::Serializer
      attributes :legal_name, :fein, :dba

      has_many :profiles
    end
  end
end

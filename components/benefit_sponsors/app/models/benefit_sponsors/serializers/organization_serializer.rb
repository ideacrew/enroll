module BenefitSponsors
  module Serializers
    class OrganizationSerializer < ActiveModel::Serializer
      attributes :legal_name, :dba
      attribute :fein, if: :is_general_organization?

      has_many :profiles


      def is_general_organization?
        object.is_a? BenefitSponsors::Organizations::GeneralOrganization
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?
          
        end
        hash
      end
    end
  end
end

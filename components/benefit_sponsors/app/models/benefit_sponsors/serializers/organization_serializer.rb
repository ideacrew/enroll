module BenefitSponsors
  module Serializers
    class OrganizationSerializer < ActiveModel::Serializer
      attributes :legal_name, :dba, :entity_kind, :entity_kind_options
      attribute :fein, if: :can_fein?
      attribute :entity_kind_options

      def can_fein?
        is_general_organization? || is_congress?
      end

      def is_general_organization?
        object.is_a? BenefitSponsors::Organizations::GeneralOrganization
      end

      def is_congress?
        object.is_a_fehb_profile?
      end

      def entity_kind_options
        object.entity_kinds
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

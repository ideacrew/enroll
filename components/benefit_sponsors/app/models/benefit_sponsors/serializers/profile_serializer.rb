module BenefitSponsors
  module Serializers
    class ProfileSerializer < ActiveModel::Serializer
      attributes :id, :entity_kind, :contact_method, :sic_code,  :rating_area_id, :entity_kind_options, :contact_method_options
      attribute :rating_area_id, if: :is_cca_employer_profile?
      attribute :sic_code, if: :is_cca_employer_profile?
      attribute :id, if: :is_persisted?

      has_many :office_locations

      def is_persisted?
        object.persisted?
      end

      def is_cca_employer_profile?
        object.is_a?(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile)
      end

      def is_dc_employer_profile?
        object.is_a?(BenefitSponsors::Organizations::AcaShopDcEmployerProfile)
      end

      def entity_kind_options
        object.entity_kinds
      end

      def contact_method_options
        object.contact_methods
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

module BenefitSponsors
  module Serializers
    class ProfileSerializer < ActiveModel::Serializer
      attributes :id, :entity_kind, :contact_method, :sic_code,  :rating_area_id, :entity_kind_options,
                   :languages_spoken, :working_hours, :accept_new_clients, :profile_type, :market_kind_options,
                    :market_kind, :language_options
      attribute :contact_method_options, if: :is_employer_profile?
      attribute :rating_area_id, if: :is_cca_employer_profile?
      attribute :sic_code, if: :is_cca_employer_profile?
      attribute :languages_spoken, if: :is_broker_profile?
      attribute :working_hours, if: :is_broker_profile?
      attribute :accept_new_clients, if: :is_broker_profile?
      attribute :market_kind_options, if: :is_broker_profile?
      attribute :market_kind, if: :is_broker_profile?
      attribute :entity_kind_options, if: :is_employer_profile?
      attribute :language_options, if: :is_broker_profile?
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

      def is_employer_profile?
        is_cca_employer_profile? || is_dc_employer_profile?
      end

      def is_broker_profile?
        object.is_a?(BenefitSponsors::Organizations::BrokerAgencyProfile)
      end

      def entity_kind_options
        object.entity_kinds
      end

      def market_kind_options
        object.market_kinds
      end

      def contact_method_options
        object.contact_methods
      end

      def profile_type
        str = object.class.to_s
        if str.match(/EmployerProfile/)
          "benefit_sponsor"
        elsif str.match(/BrokerAgencyProfile/)
          "broker_agency"
        end
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?
          hash[:entity_kind] = :s_corporation if is_broker_profile?
        end
        hash
      end
    end
  end
end

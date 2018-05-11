module BenefitSponsors
  module Organizations
    class Forms::BrokerManagementForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :employer_profile_id, String
      attribute :broker_agency_profile_id, String
      attribute :broker_role_id, String

      def broker_agency_id=(val)
        @broker_agency_profile_id = val
      end

      def self.for_create(attrs)
        create_for = new(attrs)
        create_for
      end

      def save
        persist!
      end

      def persist!
        service.assign_agencies(self)
      end

      protected

      def self.resolve_service
        Services::BrokerManagementService.new
      end

      def service
        return @service if defined?(@service)
        @service = self.class.resolve_service
      end
    end
  end
end
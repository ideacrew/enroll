module BenefitSponsors
  module Organizations
    class OrganizationForms::BrokerManagementForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :employer_profile_id, String
      attribute :broker_agency_profile_id, String
      attribute :broker_role_id, String
      attribute :termination_date, String
      attribute :direct_terminate, Boolean
      attribute :general_agency_profile_id, String
      attribute :type, String

      attr_accessor :broker_agency_profile, :general_agency_profiles, :notice

      def broker_agency_id=(val)
        @broker_agency_profile_id = val
      end

      def self.for_create(attrs)
        new(attrs)
      end

      def save
        persist!
      end

      def persist!
        service.assign_agencies(self)
      end

      def self.for_terminate(attrs)
        attrs.permit! if attrs.is_a?(ActionController::Parameters)
        new(attrs)
      end

      def self.for_default_ga(args)
        self.new(broker_agency_profile_id: args[:broker_agency_profile_id], general_agency_profile_id: args[:general_agency_profile_id], type: args[:type])
      end

      def set_default_ga(current_user)
        service.set_default_ga(self, current_user)
      end

      def termination_date=(val)
        begin
          @termination_date = Date.strptime(val,"%m/%d/%Y")
          return @termination_date
        rescue
          return nil
        end
      end

      def direct_terminate=(val)
        begin
          @direct_terminate = true if val.downcase == 'true'
          @direct_terminate = false if val.downcase == 'false'
        rescue
          return nil
        end
      end

      def terminate
        terminate!
      end

      def terminate!
        service.terminate_agencies(self)
      end

      protected

      def self.resolve_service
        BenefitSponsors::Services::BrokerManagementService.new
      end

      def service
        return @service if defined?(@service)
        @service = self.class.resolve_service
      end
    end
  end
end

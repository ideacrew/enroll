# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    # policy for will BrokerAgencyProfile, inherits from benefit_sponsors ApplicationPolicy, but methods are from main_app ApplicationPolicy
    # methods had to be duplicated due to GHAs
    class BrokerAgencyProfilePolicy < BenefitSponsors::ApplicationPolicy

      # NOTE: All methods will most likely be consolidated with the auth refactor for BrokerAgencyProfilesController

      # NOTE: this method is only used by the BrokerAgencyProfileStaffRolesController, but it acts as an extension of
      # BrokerAgencyProfilesController does not have a :new? method
      def new?
        access_to_broker_agency_profile?
      end

      def redirect_signup?
        access_to_broker_agency_profile?
      end

      def index?
        return true if individual_market_admin?
        return true if shop_market_admin?

        false
      end

      def show?
        access_to_broker_agency_profile?
      end

      def access_to_broker_agency_profile?
        return true if individual_market_admin?
        return true if shop_market_admin?
        return true if has_matching_broker_role?
        return true if has_matching_broker_agency_staff_role?

        false
      end

      def set_default_ga?
        access_to_broker_agency_profile?
      end

      def staff_index?
        return true if individual_market_admin?
        return true if shop_market_admin?
        return true if account_holder&.has_consumer_role?

        false
      end

      def family_index?
        access_to_broker_agency_profile?
      end

      def family_datatable?
        access_to_broker_agency_profile?
      end

      def commission_statements?
        access_to_broker_agency_profile?
      end

      def show_commission_statement?
        access_to_broker_agency_profile?
      end

      def download_commission_statement?
        access_to_broker_agency_profile?
      end

      def general_agency_index?
        access_to_broker_agency_profile?
      end

      def messages?
        access_to_broker_agency_profile?
      end

      def inbox?
        access_to_broker_agency_profile?
      end

      protected

      def has_matching_broker_agency_staff_role?
        staff_roles = account_holder_person&.broker_agency_staff_roles || []
        staff_roles&.any? do |sr|
          sr.active? &&
            (
              sr.broker_agency_profile_id == record.id ||
                sr.benefit_sponsors_broker_agency_profile_id == record.id
            )
        end
      end

      def has_matching_broker_role?
        broker_role = account_holder_person&.broker_role
        return false unless broker_role

        broker_role&.benefit_sponsors_broker_agency_profile_id == record.id && broker_role&.active?
      end
    end
  end
end


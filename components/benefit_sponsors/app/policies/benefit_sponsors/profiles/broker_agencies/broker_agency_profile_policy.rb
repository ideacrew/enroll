module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyProfilePolicy < BenefitSponsors::ApplicationPolicy

        def family_index?
          user&.has_hbx_staff_role? || user&.has_broker_role? || user&.has_broker_agency_staff_role?
        end

        def family_datatable?
          family_index?
        end

        def index?
          return true if individual_market_admin?
          return true if shop_market_admin?
  
          false
        end

        def show?
          return true if individual_market_admin?
          return true if shop_market_admin?
          return true if has_matching_broker_role?
  
          has_matching_broker_agency_staff_role?
        end

        def redirect_signup?
          return false if user.blank?
          self.send(:family_index?)
        end

        def staff_index?
          user&.has_hbx_staff_role? || user&.has_csr_role? || user&.has_consumer_role?
        end
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
        broker_role = account_holder_person.broker_role
        return false unless broker_role

        broker_role&.benefit_sponsors_broker_agency_profile_id == record.id && broker_role&.active?
      end
    end
  end
end

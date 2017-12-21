module SponsoredBenefits
  class ApplicationController < ActionController::Base
    before_action :set_broker_agency_profile_from_user

    private
      helper_method :active_tab

      def active_tab
        "employers-tab"
      end

      def set_broker_agency_profile_from_user
        @broker_agency_profile = ::BrokerAgencyProfile.find(current_user.person.broker_role.broker_agency_profile_id)
      end
  end
end

module SponsoredBenefits
  class ApplicationController < ActionController::Base
    before_action :set_broker_agency_profile_from_user

    private
      helper_method :active_tab

      def active_tab
        "employers-tab"
      end

      def set_broker_agency_profile_from_user
        if current_person.broker_role.present?
          @broker_agency_profile = ::BrokerAgencyProfile.find(current_person.broker_role.broker_agency_profile_id)
        end

        if active_user.has_hbx_staff_role? && params[:plan_design_organization_id].present?
          @broker_agency_profile = ::BrokerAgencyProfile.find(params[:plan_design_organization_id])
        elsif params[:plan_design_proposal_id].present?
          org = SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id]).plan_design_organization
          @broker_agency_profile = ::BrokerAgencyProfile.find(org.owner_profile_id)
        elsif params[:id].present?
          org = SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:id]).plan_design_organization
          @broker_agency_profile = ::BrokerAgencyProfile.find(org.owner_profile_id)
        end
      end

      def current_person
        current_user.person
      end

      def active_user
        current_user
      end
  end
end

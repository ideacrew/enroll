module BenefitSponsors
  module Concerns
    module ProfileRegistration

      private

      def broker_new_registration_url
        new_profiles_registration_path(profile_type: "broker_agency")
      end

      def sponsor_new_registration_url
        new_profiles_registration_path(profile_type: "benefit_sponsor")
      end

      def sponsor_show_pending_registration_url
        profiles_employers_employer_profile_show_pending(@agency.organization.employer_profile.id)
      end

      def sponsor_home_registration_url
        profiles_employers_employer_profile_path(@agency.organization.employer_profile.id, tab: 'home')
      end

      def sponsor_edit_registration_url
        edit_profiles_registration_path(@agency.organization.employer_profile.id)
      end
    end
  end
end

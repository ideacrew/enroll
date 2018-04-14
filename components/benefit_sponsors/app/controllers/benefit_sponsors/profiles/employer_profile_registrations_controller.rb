module BenefitSponsors
  module Profiles
    # Inheriting from base controller to ignore login for now, so that we can
    # do a demonstration of approach.
    class EmployerProfileRegistrationsController < ActionController::Base
      def new
        @profile_registration = ::BenefitSponsors::Organizations::EmployerProfileRegistrationForm.for_new
      end

      def create
        @profile_registration = ::BenefitSponsors::Organizations::EmployerProfileRegistrationForm.for_create(current_user, params.require[:profile_registration])
      end
    end
  end
end

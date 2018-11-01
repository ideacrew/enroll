module Exchanges
  module EmployerApplicationsHelper
     def can_terminate_application?(application)
      (application.active? || application.suspended?)
    end
     def can_cancel_application?(application)
      (BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_DRAFT_STATES + BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES + [:enrollment_ineligible, :active]).include?(application.aasm_state)
    end
  end
end
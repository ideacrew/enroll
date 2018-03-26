module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def new
        @benefit_application = build_benefit_application
      end

      def build_benefit_application
        benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.new
        benefit_application.benefit_packages.build
        benefit_application.benefit_packages.first.build_relationship_benefits
        benefit_application.benefit_packages.first.build_dental_relationship_benefits
        BenefitSponsors::Forms::BenefitApplicationForm.new(benefit_application)
      end

    end
  end
end

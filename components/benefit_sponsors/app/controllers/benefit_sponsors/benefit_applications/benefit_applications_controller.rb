module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      before_action :find_benefit_sponsorship

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

      def edit
        benefit_application = @benefit_sponsorship.find_benefit_application(params[:id])
        if params[:publish]
          @just_a_warning = !benefit_application.is_application_eligible? ? true : false
          benefit_application.application_warnings
        end
        @benefit_application = BenefitSponsors::Forms::BenefitApplicationForm.new(benefit_application)
        @benefit_application.benefit_packages.each do |benefit_package|
          benefit_package.build_relationship_benefits if benefit_package.relationship_benefits.empty?
          benefit_package.build_dental_relationship_benefits if benefit_package.dental_relationship_benefits.empty?
        end

        respond_to do |format|
          format.js { render 'edit' }
          format.html { render 'edit' }
        end
      end

      private

      def find_benefit_sponsorship
        @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id])
      end

    end
  end
end

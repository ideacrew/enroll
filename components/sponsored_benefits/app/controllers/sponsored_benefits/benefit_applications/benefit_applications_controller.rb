module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def index
        ## load quote for a given sponsorship
      end

      def new
        # initialize FormObject
      end

      def show
        # load relevant quote (not nested)
      end

      def edit
        # edit relevant quote (not nested)
      end

      def create
        # create quote for sponsorship
        @benefit_application = AcaShopCcaBenefitApplicationBuilder.new(sponsor, benefit_application_params)
        benefit_sponsorship.benefit_applications << @benefit_application.benefit_application
        benefit_sponsorship.save!
        redirect_to benefit_application_path(@benefit_application.benefit_application._id)
      end

      def update
        # update relevant quote (not nested)
        benefit_application.update_attributes(benefit_application_params)
        redirect_to benefit_application_path(benefit_application._id)
      end

      def destroy
        puts benefit_application.id
        

        benefit_application.destroy!
        redirect_to benefit_sponsorship_benefit_applications_path(benefit_application.benefit_sponsorship)
      end

      private
        helper_method :sponsor

        def sponsor
          @sponsor ||= EmployerProfile.find(benefit_sponsorship.benefit_sponsorable.customer_profile_id)
        end

        def benefit_sponsorship
          @benefit_sponsorship ||= BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id])
        end

        def benefit_application
          @benefit_application ||= BenefitApplications::BenefitApplication.find(params[:id])
        end

        def benefit_application_params
          params.require(:benefit_application).permit(:effective_period, :open_enrollment_period)
        end

    end
  end
end

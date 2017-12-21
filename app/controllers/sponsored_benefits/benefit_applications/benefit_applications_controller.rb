module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def index
        ## load quotes for a given sponsorship
        # broker / sponsor
      end

      def new
        # initialize FormObject
        # broker / sponsor
      end

      def show
        # load relevant quote (not nested)
        # benefit_application
      end

      def edit
        # edit relevant quote (not nested)
      end

      def create
        # create quote for sponsorship
        @benefit_application = AcaShopCcaBenefitApplicationBuilder.new(sponsor, benefit_application_params)
        benefit_sponsorship.benefit_applications << @benefit_application.benefit_application
        if benefit_sponsorship.save
          redirect_to benefit_application_path(@benefit_application.benefit_application._id)
        else
          @benefit_application = @benefit_application.benefit_application
          render :new
        end
      end

      def update
        # update relevant quote (not nested)
        if benefit_application.update_attributes(benefit_application_params)
          redirect_to benefit_application_path(benefit_application._id)
        else
          render :edit
        end
      end

      def destroy
        benefit_application.destroy!
        redirect_to benefit_sponsorship_benefit_applications_path(benefit_application.benefit_sponsorship)
      end

      private
        helper_method :sponsor, :broker

        def broker
          @broker ||= SponsoredBenefits::Organizations::BrokerAgencyProfile.find(params[:broker_id])
        end

        def sponsor
          @sponsor ||= ::EmployerProfile.find(params[:client_id])
        end

        def benefit_sponsorship
          broker.benefit_sponsorships.first || broker.benefit_sponsorships.new
          #@benefit_sponsorship ||= BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id])
        end

        def benefit_sponsorship_applications
          @benefit_sponsorship_applicatios ||= benefit_sponsorship.benefit_applications
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

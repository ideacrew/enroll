module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def index
      end

      def new
      end

      def create
      end

      def show
      end

      def update
      end

      def destroy
      end

      private
      helper_method :broker, :sponsor

      def broker
        @broker ||= BrokerAgencyProfile.find(params[:benefit_sponsorship_id])
      end

      def sponsor
        @sponsor ||= EmployerProfile.find(params[:sponsor_id])
      end

    end
  end
end

module BenefitSponsors
  module BenefitApplications
    class BenefitPackagesController < ApplicationController

      before_action :load_benefit_sponsorship, :load_benefit_application, :find_product_package

      # List all the benefit packages under benefit application
      def index

      end

      def new
        @benefit_package = BenefitSponsors::Forms::BenefitPackage.new(@benefit_application)
      end

      def create
        benefit_package = BenefitSponsors::Forms::BenefitPackage.new(@benefit_application).build(params[:benefit_package])
        if benefit_package && benefit_package.save
          # redirect to benefit packages index
        else
          # redirect with errors
        end
      end
    
      private

      def load_benefit_application
      end
    end
  end
end

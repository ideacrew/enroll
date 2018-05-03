module BenefitSponsors
  module BenefitPackages
    class BenefitPackagesController < ApplicationController

      def new
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_new(params.require(:benefit_application_id))
      end

      def create
      end

      def edit
      end


      private

      # def benefit_package_params
      #   params.require(:benefit_package).permit(
      #     :start_on, :end_on, :fte_count, :pte_count, :msp_count,
      #     :open_enrollment_start_on, :open_enrollment_end_on, :benefit_application_id
      #   )
      # end
    end
  end
end

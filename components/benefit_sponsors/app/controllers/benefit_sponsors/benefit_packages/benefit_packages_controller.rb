module BenefitSponsors
  module BenefitPackages
    class BenefitPackagesController < ApplicationController

      def new
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_new(params.require(:benefit_application_id))
      end

      def create
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_create(benefit_package_params)
        if @benefit_package_form.save
          flash[:notice] = "Benefit Package successfully created."
          redirect_to edit_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.service.benefit_application, @benefit_package_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_package_form)
          render :new
        end
      end

      def edit
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_edit(params.permit(:id, :benefit_application_id))
      end

      def update
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_update(params.permit(:id, :benefit_application_id))
        if @benefit_package_form.update_attributes(benefit_package_params)
          redirect_to benefit_sponsorship_benefit_applications_path(@benefit_package_form.service.benefit_application.benefit_sponsorship)
        else
          flash[:error] = error_messages(@benefit_package_form)
          render :edit
        end
      end

      def destroy
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.fetch(params.permit(:id, :benefit_application_id))
        if @benefit_package_form.destroy
          flash[:notice] = "Benefit Package successfully deleted."
          benefit_sponsorship_benefit_applications_path(@benefit_package_form.service.benefit_application.benefit_sponsorship)
        else
          falsh[:error] = error_messages(@benefit_package_form)
          # render :
        end
      end

      private

      def error_messages(object)
        object.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def benefit_package_params
        params.require(:benefit_package).permit(
          :title, :description, :probation_period_kind, :benefit_application_id,
          :sponsored_benefits_attributes => [:kind, :product_option_choice, :product_package_kind, :reference_plan_id,
            :sponsor_contribution_attributes => [ 
              :contribution_levels_attributes => [ :is_offered, :display_name, :contribution_factor]
            ]
          ]
        )
      end
    end
  end
end

# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    class BenefitPackagesController < ::BenefitSponsors::ApplicationController

      before_action :check_for_late_rates, only: [:new]

      include Pundit
      include HtmlScrubberUtil

      layout "two_column"

      def new
        authorize @benefit_package_form, :updateable?

        respond_to do |format|
          format.html
        end
      end

      def create
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_create(benefit_package_params)
        authorize @benefit_package_form, :updateable?
        if @benefit_package_form.save
          flash[:notice] = "Benefit Package successfully created."
          # TODO get redirection url from service
          if params[:add_new_benefit_package] == "true"
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application, add_new_benefit_package: true)
          elsif params[:add_dental_benefits] == "true"
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_sponsored_benefit_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application, @benefit_package_form.show_page_model, kind: "dental")
          else
            redirect_to profiles_employers_employer_profile_path(@benefit_package_form.service.employer_profile, :tab=>'benefits')
          end
        else
          flash[:error] = error_messages(@benefit_package_form)

          respond_to do |format|
            format.html { render :new }
          end
        end
      end

      def edit
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_edit(params.permit(:id, :benefit_application_id), true)
        authorize @benefit_package_form, :updateable?

        respond_to do |format|
          format.html
        end
      end

      def update
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_update(benefit_package_params.merge({:id => params.require(:id)}))
        if @benefit_package_form.update
          flash[:notice] = "Benefit Package successfully updated."
          # TODO get redirection url from service
          if params[:add_new_benefit_package] == "true"
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application, add_new_benefit_package: true)
          elsif params[:add_dental_benefits] == "true"
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_sponsored_benefit_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application, @benefit_package_form.show_page_model, kind: "dental")
          elsif params[:edit_dental_benefits] == "true"
            redirect_to edit_benefit_sponsorship_benefit_application_benefit_package_sponsored_benefit_path(@benefit_package_form.service.benefit_application.benefit_sponsorship, @benefit_package_form.show_page_model.benefit_application,
              @benefit_package_form.show_page_model, @benefit_package_form.show_page_model.dental_sponsored_benefit, kind: "dental")
          else
            redirect_to profiles_employers_employer_profile_path(@benefit_package_form.service.benefit_application.benefit_sponsorship.profile, :tab=>'benefits')
          end
        else
          flash[:error] = error_messages(@benefit_package_form)

          respond_to do |format|
            format.html { render :edit }
          end
        end
      end

      def calculate_employer_contributions
        @employer_contributions = BenefitSponsors::Forms::BenefitPackageForm.for_calculating_employer_contributions(benefit_package_params)

        respond_to do |format|
          format.json { rrender json: @employer_contributions }
        end
      end

      def calculate_employee_cost_details
        @employee_cost_details = BenefitSponsors::Forms::BenefitPackageForm.for_calculating_employee_cost_details(benefit_package_params)

        respond_to do |format|
          format.json { render json: @employee_cost_details.to_json }
        end
      end

      def destroy
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.fetch(params.permit(:id, :benefit_application_id))
        authorize @benefit_package_form, :updateable?
        if @benefit_package_form.destroy
          flash[:notice] = "Benefit Package successfully deleted."
        else
          flash[:error] = error_messages(@benefit_package_form)
        end

        respond_to do |format|
          format.js { render :js => "window.location = #{profiles_employers_employer_profile_path(@benefit_package_form.service.benefit_application.benefit_sponsorship.profile, :tab => 'benefits').to_json}" }
        end
      end

      def reference_product_summary
        @product_summary = BenefitSponsors::Forms::BenefitPackageForm.for_reference_product_summary(reference_product_params, params[:details])

        respond_to do |format|
          format.json {  render json: @product_summary }
        end
      end

      private

      def check_for_late_rates
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_new(params.require(:benefit_application_id))
        date = @benefit_package_form.service.benefit_application.start_on.to_date
        if BenefitMarkets::Forms::ProductForm.for_new(date).fetch_results.is_late_rate
          redirect_to profiles_employers_employer_profile_path(@benefit_package_form.service.employer_profile, :tab=>'benefits')
        end
      end

      def error_messages(object)
        sanitize_html(object.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"})
      end

      def benefit_package_params
        params.require(:benefit_package).permit(
          :title, :description, :probation_period_kind, :benefit_application_id, :id,
          :sponsored_benefits_attributes => [:id, :kind, :product_option_choice, :product_package_kind, :reference_plan_id,
            :sponsor_contribution_attributes => [
              :contribution_levels_attributes => [:id, :is_offered, :display_name, :contribution_factor,:contribution_unit_id]
            ]
          ]
        )
      end

      def reference_product_params
        params.permit(:benefit_application_id).merge({:sponsored_benefits_attributes => {"0" => {:reference_plan_id => params[:reference_plan_id]} }})
      end

      def employer_contribution_params
        params.permit(:id, :benefit_application_id, :sponsored_benefits_attributes => [:product_package_kind, :reference_plan_id, :id])
      end

      def new_package_url
      end

      def dental_benefits_url
      end
    end
  end
end

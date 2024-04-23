module BenefitSponsors
  module BenefitApplications
    # This controller is used to create and update benefit applications
    class BenefitApplicationsController < ::BenefitSponsors::ApplicationController
      layout "two_column"
      include Pundit
      include HtmlScrubberUtil

      def new
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_new(params.permit(:benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?

        respond_to do |format|
          format.html
        end
      end

      def create
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(application_params)
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.service.benefit_sponsorship, @benefit_application_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_application_form)
          redirect_to new_benefit_sponsorship_benefit_application_path(@benefit_application_form.benefit_sponsorship_id)
        end
      end

      def edit
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_edit(params.permit(:id, :benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?

        respond_to do |format|
          format.html
          format.js
        end
      end

      def update
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_update(params.permit(:id, :benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.update_attributes(application_params)
          flash[:notice] = "Benefit Application updated successfully."
          if @benefit_application_form.show_page_model.benefit_packages.empty?
            redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.show_page_model.benefit_sponsorship, @benefit_application_form.show_page_model)
          elsif params[:update_single].present?
            redirect_to edit_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.show_page_model.benefit_sponsorship, @benefit_application_form.show_page_model, @benefit_application_form.show_page_model.benefit_packages.first, :show_benefit_application_tile => true)
          else
            redirect_to edit_benefit_sponsorship_benefit_application_path(@benefit_application_form.show_page_model.benefit_sponsorship, @benefit_application_form.show_page_model)
          end
        else
          flash[:error] = error_messages(@benefit_application_form)

          respond_to do |format|
            format.js { render :edit }
          end
        end
      end

      def submit_application
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.fetch(params.permit(:benefit_application_id, :benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.submit_application
          flash[:notice] = "Plan Year successfully published."
          flash[:error] = error_messages(@benefit_application_form)
          respond_to do |format|
            format.js { render :js => "window.location = #{profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits').to_json}" }
          end
        elsif @benefit_application_form.is_ineligible_to_submit?
          respond_to do |format|
            format.js
          end
        else
          error_message_html = sanitize_html(@benefit_application_form.errors.messages.values.flatten.inject("") { |memo, error| "#{memo}<li>#{error}</li>" })
          flash[:error] = "Plan Year failed to publish. #{error_message_html}"
          respond_to do |format|
            format.js { render :js => "window.location = #{profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits').to_json}" }
          end
        end
      end

      def force_submit_application
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.fetch(params.permit(:benefit_application_id, :benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.force_submit_application_with_eligibility_errors
          flash[:error] = "As submitted, this application is ineligible for coverage under the "\
          "#{BenefitSponsorsRegistry[:enroll_app].setting(:short_name).item} exchange. "\
          "If information that you provided leading to this determination is inaccurate, you have "\
          "30 days from this notice to request a review by DCHL officials."
          redirect_to profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits')
        end
      end

      def revert
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.fetch(params.permit(:benefit_application_id, :benefit_sponsorship_id))
        authorize @benefit_application_form, :revert_application?
        if @benefit_application_form.revert
          flash[:notice] = "Plan Year successfully reverted to draft state."
        else
          flash[:error] = sanitize_html("Plan Year could not be reverted to draft state. #{error_messages(@benefit_application_form)}")
        end

        respond_to do |format|
          format.js { render :js => "window.location = #{profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits').to_json}" }
        end
      end

      def late_rates_check
        date = params[:start_on_date].present? ? Date.strptime(params[:start_on_date], "%m/%d/%Y") : nil
        product_form = BenefitMarkets::Forms::ProductForm.for_new(date)
        product_form = product_form.fetch_results

        respond_to do |format|
          format.json { render json: product_form.is_late_rate }
        end
      end

      private

      def error_messages(instance)
        sanitize_html(instance.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"})
      end

      def application_params
        params.require(:benefit_application).permit(
          :start_on, :end_on, :fte_count, :pte_count, :msp_count,
          :open_enrollment_start_on, :open_enrollment_end_on, :benefit_sponsorship_id
        )
      end
    end
  end
end

# frozen_string_literal: true

module FinancialAssistance
  class DeductionsController < FinancialAssistance::ApplicationController
    include NavigationHelper

    before_action :find_application_and_applicant
    before_action :set_cache_headers, only: [:index]

    # This is a before_action that checks if the application is a renewal draft and if it is, it sets a flash message and redirects to the applications_path
    # This before_action needs to be called after finding the application
    #
    # @before_action
    # @private
    before_action :check_for_uneditable_application

    def index
      authorize @applicant, :index?

      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: 'financial_assistance_nav'
    end

    def new
      authorize @applicant, :new?
      @model = @applicant.deductions.build
      render 'index', layout: 'financial_assistance_nav'
    end

    def step
      raise ActionController::UnknownFormat unless request.format.js? || request.format.html?

      @model = @applicant.deductions.build
      authorize @model, :step?

      redirect_to action: :index
    end

    def create
      authorize @applicant, :create?
      format_date(params)
      @deduction = @applicant.deductions.build permit_params(params[:deduction])
      if @deduction.save
        render :create
      else
        render :new
      end
    end

    def update
      format_date(params)
      @deduction = @applicant.deductions.find params[:id]
      authorize @deduction, :update?

      if @deduction.update_attributes permit_params(params[:deduction])
        render :update
      else
        render :edit
      end
    end

    def destroy
      @deduction = @applicant.deductions.find(params[:id])
      authorize @deduction, :destroy?
      @deduction_kind = @deduction.kind
      @deduction.destroy!

      head :ok
    end

    private

    def format_date(params)
      return if params[:deduction].blank?
      params[:deduction][:start_on] = Date.strptime(params[:deduction][:start_on].to_s, "%m/%d/%Y")
      params[:deduction][:end_on] = Date.strptime(params[:deduction][:end_on].to_s, "%m/%d/%Y") if params[:deduction][:end_on].present?
    end

    # this might not be needed anymore as forms (with dates) have come out of the YAML. Refactor and Replace with the method above.
    def format_date_params(model_params)
      model_params["start_on"] = Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
      model_params["end_on"] = Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["end_on"].present?
    end

    def build_error_messages(model)
      model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.messages.first[1][0].titleize
    end

    def find_application_and_applicant
      @application = FinancialAssistance::Application.find(params[:application_id])
      @applicant = @application.applicants.find(params[:applicant_id])
    end

    def permit_params(attributes)
      return if attributes.blank?
      attributes.permit!
    end

    def find
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.find(params[:id])
    rescue StandardError
      ''
    end
  end
end

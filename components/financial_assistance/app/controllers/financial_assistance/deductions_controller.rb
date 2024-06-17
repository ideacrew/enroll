# frozen_string_literal: true

module FinancialAssistance
  class DeductionsController < FinancialAssistance::ApplicationController
    include NavigationHelper

    before_action :find_application_and_applicant
    before_action :set_cache_headers, only: [:index]
    before_action :enable_bs4_layout, only: [:index, :new, :create, :update] if EnrollRegistry.feature_enabled?(:bs4_consumer_flow) #TODO: remove create and update from this before_action if called from elsewhere and replace with param check

    def index
      authorize @applicant, :index?

      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: resolve_layout
    end

    def new
      authorize @applicant, :new?
      @model = @applicant.deductions.build
      render 'index', layout: resolve_layout
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
      date_format = @bs4 ? "%Y-%m-%d" : "%m/%d/%Y"
      params[:deduction][:start_on] = Date.strptime(params[:deduction][:start_on].to_s, date_format)
      params[:deduction][:end_on] = Date.strptime(params[:deduction][:end_on].to_s, date_format) if params[:deduction][:end_on].present?
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

    def resolve_layout
      return @bs4 ? 'financial_assistance_progress' : 'financial_assistance_nav'
    end

    def enable_bs4_layout
      @bs4 = true
    end
  end
end

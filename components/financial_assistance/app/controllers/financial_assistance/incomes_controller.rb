# frozen_string_literal: true

module FinancialAssistance
  class IncomesController < FinancialAssistance::ApplicationController
    include NavigationHelper

    before_action :find_application_and_applicant
    before_action :set_cache_headers, only: [:index, :other]
    before_action :enable_bs4_layout, only: [:other] if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)
    before_action :conditionally_enable_bs4_layout, only: [:new, :create, :edit, :update] if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)

    layout :resolve_layout

    def index
      authorize @applicant, :index?
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
    end

    def other
      authorize @applicant, :other?
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
    end

    def new
      authorize @applicant, :new?
      render 'other'
    end

    def edit
      @income = @applicant.incomes.find params[:id]
      authorize @income, :edit?
      respond_to do |format|
        format.js { render partial: 'financial_assistance/incomes/other_income_form', locals: { income: income } }
      end
    end

    def step
      @income = @applicant.incomes.find params[:id]
      authorize @income, :step?
      redirect_to action: :other
    end

    def create
      authorize @applicant, :create?
      format_date(params)
      @income = @applicant.incomes.build permit_params(params[:income])
      if @income.save
        render :create
      else
        render :new
      end
    end

    def update
      format_date(params)
      @income = @applicant.incomes.find params[:id]
      authorize @income, :update?

      if @income.update_attributes permit_params(params[:income])
        render :update
      else
        render :edit
      end
    end

    def destroy
      authorize @applicant, :destroy?
      income_id = params['id'].split('_').last
      @income = @applicant.incomes.where(id: income_id).first
      @income&.destroy

      head :ok
    end

    private

    def format_date(params)
      return if params[:income].blank?
      params[:income][:start_on] = Date.strptime(params[:income][:start_on].to_s, "%m/%d/%Y")
      params[:income][:end_on] = Date.strptime(params[:income][:end_on].to_s, "%m/%d/%Y") if params[:income][:end_on].present?
    end

    def job_income_type
      FinancialAssistance::Income::JOB_INCOME_TYPE_KIND
    end

    def format_date_params(model_params)
      model_params["start_on"] = Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
      model_params["end_on"] = Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["end_on"].present?
    end

    def build_error_messages(model)
      model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.full_messages.join("<br />")
    end

    def update_employer_contact(_model, params)
      if params[:employer_phone].present?
        @model.build_employer_phone
        params[:employer_phone].merge!(kind: "work") # HACK: to get pass phone validations
        @model.employer_phone.assign_attributes(permit_params(params[:employer_phone]))
      end

      return unless params[:employer_address].present?
      @model.build_employer_address
      params[:employer_address].merge!(kind: "work") # HACK: to get pass phone validations
      @model.employer_address.assign_attributes(permit_params(params[:employer_address]))
    end

    def find_application_and_applicant
      @application = FinancialAssistance::Application.find(params[:application_id])
      @applicant = @application.active_applicants.find(params[:applicant_id])
    end

    def permit_params(attributes)
      return if attributes.blank?
      attributes.permit!
    end

    def find
      FinancialAssistance::Application.find(params[:application_id]).active_applicants.find(params[:applicant_id]).incomes.find(params[:id])
    rescue StandardError
      ''
    end

    def conditionally_enable_bs4_layout
      enable_bs4_layout if params[:bs4] == "true"
    end

    def enable_bs4_layout
      @bs4 = true
    end

    def resolve_layout
      case action_name
      when "index", "step", "new"
        "financial_assistance_nav"
      when "other"
        EnrollRegistry.feature_enabled?(:bs4_consumer_flow) ? "financial_assistance_progress" : "financial_assistance"
      else
        "financial_assistance"
      end
    end
  end
end

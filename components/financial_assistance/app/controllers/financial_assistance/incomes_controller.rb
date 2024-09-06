# frozen_string_literal: true

module FinancialAssistance
  class IncomesController < FinancialAssistance::ApplicationController
    include NavigationHelper

    before_action :find_application_and_applicant
    before_action :set_cache_headers, only: [:index, :other]

    # This is a before_action that checks if the application is a renewal draft and if it is, it sets a flash message and redirects to the applications_path
    # This before_action needs to be called after finding the application
    #
    # @before_action
    # @private
    before_action :check_for_uneditable_application

    layout "financial_assistance_nav", only: [:index, :other, :new, :step]

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
  end
end

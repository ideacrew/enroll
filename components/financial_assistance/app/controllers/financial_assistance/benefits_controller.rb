# frozen_string_literal: true

module FinancialAssistance
  class BenefitsController < FinancialAssistance::ApplicationController
    include NavigationHelper

    before_action :find_application_and_applicant
    before_action :set_cache_headers, only: [:index]
    before_action :enable_bs4_layout, only: [:index] if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)

    layout :resolve_layout

    def index
      # Authorizing on applicant since no benefit records may exist on index page
      # TODO: Use policy context to pass applicant to BenefitPolicy
      authorize @applicant, :index?

      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url

      respond_to do |format|
        format.html
      end
    end

    def new
      # Authorizing on applicant before benefit record is built on it
      authorize @applicant, :new?

      respond_to do |format|
        format.html { render 'index', layout: 'financial_assistance_nav' }
      end
    end

    def step
      raise ActionController::UnknownFormat unless request.format.js? || request.format.html?

      @model = @applicant.benefits.build
      authorize @model, :step?

      redirect_to action: :index
    end

    def create
      raise ActionController::UnknownFormat unless request.format.js? || request.format.html?

      format_date(params)
      @benefit = @applicant.benefits.build permit_params(params[:benefit])
      authorize @benefit, :create?

      @benefit_kind = @benefit.kind
      @benefit_insurance_kind = @benefit.insurance_kind

      if @benefit.save
        render :create, :locals => { kind: params[:benefit][:kind], insurance_kind: params[:benefit][:insurance_kind] }
      else
        render head: 'ok'
      end
    end

    def update
      format_date(params)
      @benefit = @applicant.benefits.find params[:id]
      authorize @benefit, :update?

      if @benefit.update_attributes permit_params(params[:benefit])
        respond_to do |format|
          format.js { render :update, :locals => { kind: params[:benefit][:kind], insurance_kind: params[:benefit][:insurance_kind] } }
        end
      else
        respond_to do |format|
          format.js { render head: 'ok' }
        end
      end
    end

    def destroy
      @benefit = @applicant.benefits.find(params[:id])
      authorize @benefit, :destroy?

      @benefit_kind = @benefit.kind
      @benefit_insurance_kind = @benefit.insurance_kind
      @benefit.destroy!

      head :ok
    end

    private

    def format_date(params)
      params[:benefit][:start_on] = Date.strptime(params[:benefit][:start_on].to_s, "%m/%d/%Y")
      params[:benefit][:end_on] = Date.strptime(params[:benefit][:end_on].to_s, "%m/%d/%Y") if params[:benefit][:end_on].present?
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

    def build_error_messages(model)
      model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.messages.first[1][0].titleize
    end

    def find_application_and_applicant
      @application = FinancialAssistance::Application.find(params[:application_id])
      @applicant = @application.active_applicants.find(params[:applicant_id])
    end

    def permit_params(attributes)
      attributes.permit!
    end

    def find
      FinancialAssistance::Application.find(params[:application_id]).active_applicants.find(params[:applicant_id]).benefits.where(id: params[:id]).last || nil
    end

    def format_date_params(model_params)
      model_params["start_on"] = Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["start_on"].present?
      model_params["end_on"] = Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["end_on"].present?
    end

    def enable_bs4_layout
      @bs4 = true
    end

    def resolve_layout
      case action_name
      when "index"
        EnrollRegistry.feature_enabled?(:bs4_consumer_flow) ? "financial_assistance_progress" : "financial_assistance_nav"
      else
        "financial_assistance"
      end
    end
  end
end

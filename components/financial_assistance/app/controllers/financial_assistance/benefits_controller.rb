# frozen_string_literal: true

module FinancialAssistance
  class BenefitsController < FinancialAssistance::ApplicationController
    include ::UIHelpers::WorkflowController
    include NavigationHelper

    before_action :find_application_and_applicant
    before_action :load_support_texts, only: [:index, :create, :update]

    def index
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: 'financial_assistance_nav'
      # @insurance_kinds = FinancialAssistance::Benefit::INSURANCE_TYPE
    end

    def new
      @model = @applicant.benefits.build
      load_steps
      current_step
      render 'workflow/step', layout: 'financial_assistance_nav'
    end

    def step # rubocop:disable Metrics/CyclomaticComplexity TODO: Remove this
      save_faa_bookmark(request.original_url.gsub(%r{/step.*}, "/step/#{@current_step.to_i}"))
      set_admin_bookmark_url
      flash[:error] = nil
      model_name = @model.class.to_s.split('::').last.downcase
      model_params = params[model_name]
      @model.clean_conditional_params(params) if model_params.present?
      format_date_params model_params if model_params.present?
      @model.assign_attributes(permit_params(model_params)) if model_params.present?
      update_employer_contact(@model, params) if @model.insurance_kind == "employer_sponsored_insurance"

      if params.key?(model_name)
        if @model.save(context: "step_#{@current_step.to_i}".to_sym)
          @current_step = @current_step.next_step if @current_step.next_step.present?
          if params.key? :last_step
            @model.update_attributes!(workflow: { current_step: 1 })
            flash[:notice] = 'Benefit Info Added.'
            redirect_to application_applicant_benefits_path(@application, @applicant)
          else
            @model.update_attributes!(workflow: { current_step: @current_step.to_i })
            render 'workflow/step', layout: 'financial_assistance_nav'
          end
        else
          flash[:error] = build_error_messages(@model)
          render 'workflow/step', layout: 'financial_assistance_nav'
        end
      else
        render 'workflow/step', layout: 'financial_assistance_nav'
      end
    end

    def create
      format_date(params)
      @benefit = @applicant.benefits.build permit_params(params[:benefit])
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
      if @benefit.update_attributes permit_params(params[:benefit])
        render :update, :locals => { kind: params[:benefit][:kind], insurance_kind: params[:benefit][:insurance_kind] }
      else
        render head: 'ok'
      end
    end

    def destroy
      @benefit = @applicant.benefits.find(params[:id])
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
  end
end

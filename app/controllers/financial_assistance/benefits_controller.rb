class FinancialAssistance::BenefitsController < ApplicationController
  include UIHelpers::WorkflowController
  include NavigationHelper

  before_filter :find_application_and_applicant
  before_action :setup_navigation

   def new
    @model = @applicant.benefits.build
    load_steps
    current_step
    render 'workflow/step', layout: 'financial_assistance'
  end

  def step
    #TODO has_health_coverage_benefit should be updated based on the info updated for is_eligible and is_enrolled.

    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]

    @model.clean_conditional_params(params) if model_params.present?

    if model_params.present? && model_params[:is_enrolled] == "false" && model_params[:is_eligible] == "false"
      flash[:notice] = 'No Benifit Info Added.'
      @applicant.update_attributes!(has_insurance: false)
      redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
    else
      format_date_params_enrolled model_params if model_params.present? && model_params.present? && model_params[:is_enrolled] == "true"
      format_date_params_eligible model_params if model_params.present? && model_params[:is_eligible] == "true"

      @model.assign_attributes(permit_params(model_params)) if model_params.present?

      update_employer_contact(@model, params) if @model.is_eligible && @model.kind == "employer_sponsored_insurance"

      if params.key?(model_name)
        @model.workflow = { current_step: @current_step.to_i + 1 }
        @current_step = @current_step.next_step if @current_step.next_step.present?
      else
        @model.workflow = { current_step: @current_step.to_i }
      end

      begin
        @model.save!
        if params[:commit] == "Finish"
          flash[:notice] = 'Benefit Info Added.'
          redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
        else
          render 'workflow/step', layout: 'financial_assistance'
        end
      rescue
        flash[:error] = build_error_messages(@model)
        render 'workflow/step', layout: 'financial_assistance'
      end
    end
  end

  def destroy
    benefit = @applicant.benefits.find(params[:id])
    benefit.destroy!
    flash[:success] = "Benefit deleted - (#{benefit.kind})"
    redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
  end

  private
  
  def update_employer_contact model, params
    if params[:employer_phone].present?
      @model.build_employer_phone
      params[:employer_phone].merge!(kind: "work") # hack to get pass phone validations
      @model.employer_phone.assign_attributes(permit_params(params[:employer_phone]))
    end
    if params[:employer_address].present?
      @model.build_employer_address
      params[:employer_address].merge!(kind: "work") # hack to get pass phone validations
      @model.employer_address.assign_attributes(permit_params(params[:employer_address]))
    end
  end

  def build_error_messages(model)
    model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
  end

  def find_application_and_applicant
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
  end

  def create
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
    @model = @applicant.benefits.build
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).benefits.find(params[:id])
    rescue
      nil
    end
  end

  def format_date_params_enrolled model_params
    model_params["enrolled_start_on"]=Date.strptime(model_params["enrolled_start_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["enrolled_start_on"].present?
    model_params["enrolled_end_on"]=Date.strptime(model_params["enrolled_end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["enrolled_end_on"].present?
  end

  def format_date_params_eligible model_params
    model_params["eligible_start_on"]=Date.strptime(model_params["eligible_start_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["eligible_start_on"].present?
    model_params["eligible_end_on"]=Date.strptime(model_params["eligible_end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["eligible_end_on"].present?
  end

  def setup_navigation
    @selectedTab = "healthCoverage"
    @allTabs = NavigationHelper::getAllYmlTabs
  end
end

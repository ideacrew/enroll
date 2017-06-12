class FinancialAssistance::BenefitsController < ApplicationController
  include UIHelpers::WorkflowController
  include NavigationHelper

  before_filter :find_application_and_applicant

   def new
    @selectedTab = "healthCoverage"
    @allTabs = NavigationHelper::getAllYmlTabs
    @model = @applicant.benefits.build
    load_steps
    current_step
    render 'workflow/step'
  end

  def step
    @selectedTab = "healthCoverage"
    @allTabs = NavigationHelper::getAllYmlTabs
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]

    model_params["start_on"]=Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
    model_params["end_on"]=Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present?

    @model.update_attributes!(permit_params(model_params)) if model_params.present?
    update_employer_contact(@model, params)

    if params.key?(model_name)
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step
    else
      @model.workflow = { current_step: @current_step.to_i }
    end
    @model.save!
    if params[:commit] == "Finish"
      flash[:notice] = 'Benefit Info Added.'
      redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
    else
      render 'workflow/step'
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
      @model.employer_phone.update_attributes!(permit_params(params[:employer_phone]))
    end
    if params[:employer_address].present?
      @model.build_employer_address
      params[:employer_address].merge!(kind: "work") # hack to get pass phone validations
      @model.employer_address.update_attributes!(permit_params(params[:employer_address]))
    end
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
end

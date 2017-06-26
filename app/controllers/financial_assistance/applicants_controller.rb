class FinancialAssistance::ApplicantsController < ApplicationController
  include UIHelpers::WorkflowController
  include NavigationHelper

  before_filter :find, :find_application


  def edit
    @selectedTab = "taxInfo"
    @allTabs = NavigationHelper::getAllYmlTabs
    @applicant = @application.applicants.find(params[:id])
  end

  def step
    case @current_step.heading.downcase
      when "other questions"
        @selectedTab = "otherQuestions"
      when "tax info"
        @selectedTab = "taxInfo"
      else
        @selectedTab = "placeholder"
    end
    @allTabs = NavigationHelper::getAllYmlTabs

    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]

    @model.assign_attributes(permit_params(model_params)) if model_params.present?

    if params.key?(model_name)
		  @model.workflow = { current_step: @current_step.to_i + 1 }
		  @current_step = @current_step.next_step if @current_step.next_step.present?
    else
      @model.workflow = { current_step: @current_step.to_i }
    end

    begin
      @model.save!(context: :submission) if model_params[:is_pregnant].present?
      @model.save!

      if params[:commit] == "Finish"
        redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
      else
        render 'workflow/step', layout: 'financial_assistance'
      end
    rescue
      flash[:error] = build_error_messages(@model)
      render 'workflow/step', layout: 'financial_assistance'
    end
  end


  private

  def build_error_messages(model)
    model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
  end

  def find_application
    @application = FinancialAssistance::Application.find(params[:application_id])
  end

  def find
    @applicant = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:id])
  end

  def permit_params(attributes)
    attributes.permit!
  end
end

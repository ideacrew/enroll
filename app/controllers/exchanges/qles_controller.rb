class Exchanges::QlesController < ApplicationController
  before_action :set_qle_and_attributes, only: [:deactivation_form, :edit]
  before_action :can_add_custom_qle?, only: [:manage_qle]
    # TODO: We need to discuss the design/naming conventions used here
  # the new/create manage is essentially just a redirect wizard.

  # TODO: The QLE's will have to be generated as instance variables based on
  # whether or not theyh're a member of the right market kind, whether or not
  # they're eligible for deactivation, etc.

  skip_before_action :verify_authenticity_token, only: [:deactivate, :create]

  def manage
    # TODO: Fix these scopes, probably hide them behind a JSON serializer
    # TODO: Consider adding a blank option, and then assure in the qle_kind_wizard
    # that the submit button doesn't work unless a option with a value is selected.
    @editable_qles = QualifyingLifeEventKind.editable
    @deactivatable_qles = QualifyingLifeEventKind.not_set_for_deactivation
  end
  
  # TODO: All of these forms will be found in
  # app/javascript/incremental_angular/app/admin/qle_kinds/
  def manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_create(permitted_params)
    attrs = {market_kind: @manage_qle.market_kind}
    if params[:manage_qle][:action] == 'new_qle'
      redirect_to new_qle_path(attrs) and return
    elsif params[:manage_qle][:action] == 'modify_qle'
      qle = QualifyingLifeEventKind.find(params[:id])
      redirect_to edit_qle_path(qle, attrs) and return
    elsif params[:manage_qle][:action] == 'deactivate_qle'
      qle = QualifyingLifeEventKind.find(params[:id])
      redirect_to deactivation_form_qle_path(qle, attrs) and return
    end
  end

  def deactivation_form
    @qle = QualifyingLifeEventKind.find(params[:id])
  end

  def question_flow 
    qle = QualifyingLifeEventKind.find(params[:id])
    redirect_to question_flow_exchanges_qle(qle, attrs) and return
  end


  # TODO: This works, but needs to be refactored to adhere to
  # Dan's web service conventions
  # TODO 2: In the deactivate model, we need to add some constraints
  # for the end on dates that they can use.
  def deactivate
    @qle = QualifyingLifeEventKind.find(params[:data]["_id"])
    end_on_date = Date.strptime(params[:data][:end_on], '%m/%d/%Y')
    if @qle.update_attributes!(end_on: end_on_date)
      flash[:notice] = "Successfully deactivated QualifyingLifeEventKind."
    else
      flash[:error] = "Unable to update QualifyingLifeEventKind."
    end
    respond_to do |format|
      format.json { head :no_content, :location => manage_exchanges_qles_path }
    end
  end

  # TODO: This is the progress for the updated deactivate action
  # def deactivate
  # TODO: Put pundit here
  # Service invocation using parameters and user
  #  result = Admin::QleKinds::DeactivateService.call(current_user, params.require("data").permit!)
  #  respond_to do |format|
  #    format.json do 
  #      if result.success?
  #        redirect_to manage_exchanges_qles_path
  #      else
  #        render :json => { errors: result.errors.to_json }
  #      end
  #    end
  #  end
  # end

  def creation_form
    @qle = ::Forms::QleForm.for_create(permitted_params)
  end

  def edit
    @qle = ::Forms::QleForms::QleForm.for_edit(@qle_form_attributes)
  end

  def update
    @qle = ::Forms::QleForm.for_update(permitted_params)
  end

  def new
    @qle = QualifyingLifeEventKind.new
    @qle.custom_qle_questions.build
    #@qle = ::Forms::QleForms::QleForm.for_new
  end

  # TODO: Refactor this according to standards
  def create
    # TODO: For some reason when we hit the submit form in angular
    # Its not redirecting?
    
    # <Put pundit here>

    # Service invocation using parameters and user
    result = Admin::QleKinds::CreateService.call(current_user, params.require("data").permit!)
    respond_to do |format|
      format.json do 
        if result.success?
        else
          render :json => { errors: result.errors.to_json }
        end
      end
    end

    qle_kind_data = params["data"]
    new_qle = QualifyingLifeEventKind.new(
      title: qle_kind_data["title"],
      tool_tip: qle_kind_data["tool_tip"],
      action_kind: qle_kind_data["action_kind"],
      reason: qle_kind_data["reason"],
      market_kind: qle_kind_data["market_kind"],
      is_self_attested: qle_kind_data["is_self_attested"] == 'Yes' ? true : false,
      effective_on_kinds: qle_kind_data["effective_on_options"],
      pre_event_sep_in_days: qle_kind_data["pre_event_sep_eligibility"],
      post_event_sep_in_days: qle_kind_data["post_event_sep_eligibility"]
    )
    if new_qle.save
      flash[:notice] = "Successfully created QualifyingLifeEventKind."
    else
      flash[:error] = "Unable to create QualifyingLifeEventKind."
    end
    redirect_to manage_exchanges_qles_path
  end
  
  # TODO: Don't forget to add strong params where applicable
  private

  def can_add_custom_qle?
    unless authorize HbxProfile, :can_add_custom_qle?
      redirect_to root_path, :flash => { :error => "Access not allowed" }
    end
  end

  def set_qle_and_attributes
    @qle = QualifyingLifeEventKind.find(params[:id])
    @qle_form_attributes = @qle.attributes
  end

  def permitted_params
    params.permit!.to_h
  end
end

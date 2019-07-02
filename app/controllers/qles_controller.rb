class QlesController < ApplicationController
  before_action :set_qle_and_attributes, only: [:deactivation_form, :edit]
  # TODO: We need to discuss the design/naming conventions used here
  # the new/create manage is essentially just a redirect wizard.

  # TODO: The QLE's will have to be generated as instance variables based on
  # whether or not theyh're a member of the right market kind, whether or not
  # they're eligible for deactivation, etc.

  skip_before_action :verify_authenticity_token, only: [:deactivate]

  def manage
    # TODO: Fix these scopes, probably hide them behind a JSON serializer
    # TODO: Consider adding a blank option, and then assure in the qle_kind_wizard
    # that the submit button doesn't work unless a option with a value is selected.
    @editable_qles = QualifyingLifeEventKind.all
    @deactivatable_qles = QualifyingLifeEventKind.all
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

  def deactivate
    respond_to do |format|
      format.json { head :no_content, :location => manage_qles_path }
    end
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
    @qle = ::Forms::QleForms::QleForm.for_new
  end

  def create
    @qle = ::Forms::QleForm.for_create(permitted_params)
  end

  private

  def set_qle_and_attributes
    @qle = QualifyingLifeEventKind.find(params[:id])
    @qle_form_attributes = @qle.attributes
  end

  def permitted_params
    params.permit!.to_h
  end
end

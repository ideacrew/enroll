class QlesController < ApplicationController
  before_action :set_qle_and_attributes, only: [:deactivation_form, :edit]
  # TODO: We need to discuss the design/naming conventions used here
  # the new/create manage is essentially just a redirect wizard.

  # TODO: The QLE's will have to be generated as instance variables based on
  # whether or not theyh're a member of the right market kind, whether or not
  # they're eligible for deactivation, etc. We're going to switch the stimulus to
  # Angular to facilitate this.
  def manage
    # TODO: Fix these scopes, probably hide them behind a JSON serializer
    @editable_qles = QualifyingLifeEventKind.all
    @deactivatable_qles = QualifyingLifeEventKind.all
  end

  def manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_create(permitted_params)
    attrs = {market_kind: @manage_qle.market_kind}
    if params[:manage_qle][:action] == 'new_qle'
      redirect_to new_qle_path(attrs) and return
    elsif params[:manage_qle][:action] == 'modify_qle'
      qle = QualifyingLifeEventKind.find(params[:id])
      redirect_to edit_qle_path(qle, attrs) and return
    elsif params[:manage_qle][:action] == 'deactivate_qle'
      # TODO: should redirect to deactivation_form_qle_path(qle, attrs)
      qle = QualifyingLifeEventKind.find(params[:id])
      redirect_to deactivation_form_qle_path(qle, attrs) and return
    end
  end

  def deactivation_form
    @qle = ::Forms::QleForms::QleForm.for_deactivation_form(@qle_form_attributes)
  end

  def deactivate
    @qle = ::Forms::QleForm.for_deactivate(permitted_params)
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

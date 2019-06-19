class QlesController < ApplicationController
  def new_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_new(permitted_params)
  end

  def create_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_create(permitted_params)
    attrs = {market_kind: @manage_qle.market_kind}
    if params[:manage_qle][:action] == 'new_qle'
      redirect_to new_qle_path(attrs) and return
    elsif params[:manage_qle][:action] == 'modify_qle'
      # TODO: Make edit path
      redirect_to edit_manage_qle_path(attrs) and return
    elsif params[:manage_qle][:action] == 'deactivate_qle'
      # TODO: make deactivate path
      redirect_to new_qle_path(attrs) and return
    end
  end

  def edit_manage_qle
  end

  def update

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

  def permitted_params
    params.permit!.to_h
  end
end

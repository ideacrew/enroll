class QlesController < ApplicationController
  def new_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_new(params.permit!.to_h)
  end

  def create_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_create(params.permit!.to_h)
    attrs = {market_kind: @manage_qle.market_kind}
    if params[:manage_qle][:action] == 'new_qle'
      redirect_to new_qle_path(attrs) and return
    elsif params[:manage_qle][:action] == 'modify_qle'
      # TODO: Make edit path
      redirect_to new_qle_path(attrs) and return
    elsif params[:manage_qle][:action] == 'deactivate_qle'
      # TODO: make deactivate path
      redirect_to new_qle_path(attrs) and return
    end
  end

  def edit

  end

  def update

  end

  def new
    @qle = QualifyingLifeEventKind.new
    @qle.custom_qle_questions.build
  end

  def create
    # @qle = ::Forms::QleForm.for_create(params)
  end
end

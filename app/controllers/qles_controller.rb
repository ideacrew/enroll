class QlesController < ApplicationController

  # before_action :can_view_manage_qle?

  def new_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_new(params.permit!.to_h)
  end

  def create_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_create(params.permit!.to_h)
    attrs = {market_kind: @manage_qle.market_kind}
    redirect_to new_qle_path(attrs)
  end

  def new
    @qle = QualifyingLifeEventKind.new
  end

  def create
    # @qle = ::Forms::QleForm.for_create(params)
  end

  private

  # def can_view_manage_qle?
  #   unless authorize @manage_qle, :view_manage_qle?, policy_class: QlePolicy
  #    redirect_to root_path, :flash => { :error => "Access view/manage qles not allowed." }
  #   end
  # end
end

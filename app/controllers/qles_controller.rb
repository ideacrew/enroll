class QlesController < ApplicationController

  def new_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_new(params.permit!.to_h)
  end

  def create_manage_qle
    @manage_qle = ::Forms::ManageQleForm.for_create(params.permit!.to_h)
    attrs = {market_kind: @manage_qle.market_kind}
    redirect_to new_qle_path(attrs)
  end

  def new
    @qle = ::Forms::QleForm.for_new(params.permit!.to_h)
  end

  def create
    @qle = ::Forms::QleForm.for_create(params)
  end
end

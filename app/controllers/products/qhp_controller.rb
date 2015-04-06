class Products::QhpController < ApplicationController

  def comparison
    @qhps = Products::Qhp.where(:standard_component_id.in => params[:standard_component_ids]).to_a
    respond_to do |format|
      format.html
      format.js
    end
  end

  def summary
    sc_id = params.permit(:standard_component_id)[:standard_component_id][0..13]
    @qhp = Products::Qhp.where(standard_component_id: sc_id).to_a.first
    respond_to do |format|
      format.html
      format.js
    end
  end
end

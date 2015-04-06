class Products::QhpController < ApplicationController

  def comparison
    random_ids = Products::Qhp.pluck(:id).shuffle[0..2]
    @qhps = Products::Qhp.where(:_id.in => random_ids).to_a
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

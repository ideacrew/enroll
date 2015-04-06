class Products::QhpController < ApplicationController

  def comparison
    params.permit("standard_component_ids")
    found_params = params["standard_component_ids"].map { |str| str[0..13] }
    @qhps = Products::Qhp.where(:standard_component_id.in => found_params).to_a
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

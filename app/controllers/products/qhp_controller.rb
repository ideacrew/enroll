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
    new_params = params.permit(:standard_component_id, :hbx_enrollment_id)
    hbx_enrollment_id = new_params[:hbx_enrollment_id]
    sc_id = new_params[:standard_component_id][0..13]
    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    @benefit_group = @hbx_enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @qhp = Products::Qhp.where(standard_component_id: sc_id).to_a.first
    @plan = PlanCostDecorator.new(@qhp.plan, @hbx_enrollment, @benefit_group, @reference_plan)
    respond_to do |format|
      format.html
      format.js
    end
  end
end
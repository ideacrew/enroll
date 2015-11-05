class Products::QhpController < ApplicationController
  include ContentType
  include Aptc
  include Acapi::Notifiers
  extend Acapi::Notifiers
  before_action :set_current_person, only: [:comparison, :summary]
  before_action :set_kind_for_market_and_coverage, only: [:comparison, :summary]

  def comparison
    params.permit("standard_component_ids", :hbx_enrollment_id)
    found_params = params["standard_component_ids"].map { |str| str[0..13] }

    @standard_component_ids = params[:standard_component_ids]
    @hbx_enrollment_id = params[:hbx_enrollment_id]
    @active_year = params[:active_year]
    if @market_kind == 'employer_sponsored' and (@coverage_kind == 'health' || @coverage_kind == "dental") # 2016 plans have shop dental plans too.
      @benefit_group = @hbx_enrollment.benefit_group
      @plans = @benefit_group.decorated_elected_plans(@hbx_enrollment)
      @reference_plan = @benefit_group.reference_plan
      @qhps = find_qhp_cost_share_variances.each do |qhp|
        qhp[:total_employee_cost] = PlanCostDecorator.new(qhp.plan, @hbx_enrollment, @benefit_group, @reference_plan).total_employee_cost
      end
    else
      tax_household = get_shopping_tax_household_from_person(current_user.person, @hbx_enrollment.effective_on.year)
      @plans = @hbx_enrollment.decorated_elected_plans(@coverage_kind)
      @qhps = find_qhp_cost_share_variances

      @qhps = @qhps.each do |qhp|
        qhp[:total_employee_cost] = UnassistedPlanCostDecorator.new(qhp.plan, @hbx_enrollment, session[:elected_aptc], tax_household).total_employee_cost
      end

    end
    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data(Products::Qhp.csv_for(@qhps, @visit_types), type: csv_content_type, filename: "comparsion_plans.csv")
      end
    end
  end


  def summary
    @standard_component_ids = [] << @new_params[:standard_component_id]
    @active_year = params[:active_year]
    @qhp = find_qhp_cost_share_variances.first
    @source = params[:source]
    if @market_kind == 'employer_sponsored' and (@coverage_kind == 'health' || @coverage_kind == "dental")
      @benefit_group = @hbx_enrollment.benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plan = PlanCostDecorator.new(@qhp.plan, @hbx_enrollment, @benefit_group, @reference_plan)
    else
      @plan = UnassistedPlanCostDecorator.new(@qhp.plan, @hbx_enrollment)
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  private


  def set_kind_for_market_and_coverage
    @new_params = params.permit(:standard_component_id, :hbx_enrollment_id)
    hbx_enrollment_id = @new_params[:hbx_enrollment_id]
    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    if @hbx_enrollment.blank?
      error_message = {
        :error => {
          :message => "qhp_controller: HbxEnrollment missing: #{hbx_enrollment_id} for person #{@person && @person.try(:id)}",
        },
      }
      log(JSON.dump(error_message), {:severity => 'critical'})
      render file: 'public/500.html', status: 500
      return
    end
    @enrollment_kind = (params[:enrollment_kind] == "sep" || @hbx_enrollment.enrollment_kind == "special_enrollment") ? "sep" : ''
    @market_kind = (params[:market_kind] == "shop" || @hbx_enrollment.kind == "employer_sponsored") ? "employer_sponsored" : "individual"
    @coverage_kind = (params[:coverage_kind].present? ? params[:coverage_kind] : @hbx_enrollment.coverage_kind)


    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @visit_types = @coverage_kind == "health" ? Products::Qhp::VISIT_TYPES : Products::Qhp::DENTAL_VISIT_TYPES
  end

  def find_qhp_cost_share_variances
    Products::QhpCostShareVariance.find_qhp_cost_share_variances(@standard_component_ids, @active_year.to_i)
  end

end

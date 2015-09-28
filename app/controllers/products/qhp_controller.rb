class Products::QhpController < ApplicationController
  before_action :set_kind_for_market_and_coverage, only: [:comparison, :summary]

  def comparison
    params.permit("standard_component_ids", :hbx_enrollment_id)
    found_params = params["standard_component_ids"].map { |str| str[0..13] }

    @standard_component_ids = params[:standard_component_ids]
    @hbx_enrollment_id = params[:hbx_enrollment_id]

    if @market_kind == 'employer_sponsored' and @coverage_kind == 'health'
      @benefit_group = @hbx_enrollment.benefit_group
      @reference_plan = @benefit_group.reference_plan
      @qhps = Products::Qhp.where(:standard_component_id.in => found_params, active_year: params[:active_year].to_i).to_a.each do |qhp|
        qhp[:total_employee_cost] = PlanCostDecorator.new(qhp.plan, @hbx_enrollment, @benefit_group, @reference_plan).total_employee_cost
      end
    else
      tax_household = current_user.person.primary_family.latest_household.tax_households.last
      elected_aptc_pct = session[:elected_aptc_pct]
      elected_aptc_pct = elected_aptc_pct.present? ? elected_aptc_pct.to_f : 0.85

      @qhps = Products::Qhp.where(:standard_component_id.in => found_params, active_year: params[:active_year].to_i).to_a.select do |qhp|
        params["standard_component_ids"].include? qhp.plan.try(:hios_id).try(:to_s)
      end
      @qhps = @qhps.each do |qhp|
        qhp[:total_employee_cost] = UnassistedPlanCostDecorator.new(qhp.plan, @hbx_enrollment, elected_aptc_pct, tax_household).total_employee_cost
      end
    end
    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data(csv_for(@qhps), type: csv_content_type, filename: "comparsion_plans.csv")
      end
    end
  end


  def summary
    sc_id = @new_params[:standard_component_id][0..13]
    @qhp = Products::Qhp.by_hios_id_and_active_year(sc_id, params[:active_year]).first
    if @market_kind == 'employer_sponsored' and @coverage_kind == 'health'
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
    params[:market_kind] = params[:market_kind] == "shop" ? @hbx_enrollment.kind : params[:market_kind]
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'employer_sponsored'
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
  end

  def csv_for(qhps)
    (output = "").tap do 
      CSV.generate(output) do |csv|
        csv_ary = []
        csv_ary << ["Carrier", "Plan Name", "Your Cost", "Provider NetWork", "Plan Benefits"] + Products::Qhp::VISIT_TYPES
        qhps.each do |qhp|
          arry1 = [
            qhp.plan.carrier_profile.organization.legal_name,
            qhp.plan_marketing_name, 
            "$#{qhp[:total_employee_cost].round(2)}", 
            qhp.plan.nationwide ? "Nationwide" : "DC Area Network",
            "In Network"
          ]
          arry2 = [
            "","","","","Out of Network"
          ]
          Products::Qhp::VISIT_TYPES.each do |visit_type|
            matching_benefit = qhp.qhp_benefits.detect { |qb| qb.benefit_type_code == visit_type } 
            if matching_benefit 
              deductible = matching_benefit.find_deductible 
              arry1 << deductible.copay_in_network_tier_1 
              arry2 << deductible.copay_out_of_network
            end 
          end
          csv_ary << arry1
          csv_ary << arry2
        end

        inversion = convert_csv(csv_ary)
        inversion.each do |row|
          csv << row
        end
      end
    end
  end

  def convert_csv(arr)
    row = arr.count
    column = arr.first.count

    inversion = Array.new(column){ Array.new(row, 0)}
    row.times do |r|
      column.times do |c|
        inversion[c][r] = arr[r][c]
      end
    end
    inversion
  end

  def csv_content_type
    case request.user_agent
      when /windows/i 
        'application/vnd.ms-excel'
      else
        'text/csv'
    end
  end
end

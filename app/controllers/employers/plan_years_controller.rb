class Employers::PlanYearsController < ApplicationController
  before_action :find_employer, except: [:recommend_dates]
  before_action :generate_carriers_and_plans, except: [:recommend_dates]

  def new
    @plan_year = build_plan_year
  end

  def create
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    @plan_year.benefit_groups.each do |benefit_group|
      benefit_group.elected_plans = case benefit_group.plan_option_kind
                                    when "single_plan"
                                      Plan.where(id: benefit_group.reference_plan_id).first
                                    when "single_carrier"
                                      Plan.valid_shop_health_plans("carrier", benefit_group.carrier_for_elected_plan)
                                    when "metal_level"
                                      Plan.valid_shop_health_plans("metal_level", benefit_group.metal_level_for_elected_plan)
                                    end
    end
    if @plan_year.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def reference_plan_options
    @kind = params[:kind]
    @key = params[:key]
    @target = params[:target]

    @plans = case @kind
            when "carrier"
              Plan.valid_shop_health_plans("carrier", @key)
            when "metal-level"
              Plan.valid_shop_health_plans("metal_level", @key)
            else
              []
            end
  end

  def search_reference_plan
    @location_id = params[:location_id]
    @plan = Plan.find(params[:reference_plan_id])
    @premium_tables = @plan.premium_table_for(Date.parse(params[:start_on]))
  end

  def calc_employer_contributions
    @location_id = params[:location_id]
    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })
    
    @plan = Plan.find(params[:reference_plan_id])
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    @plan_year.benefit_groups[0].reference_plan = @plan

    @employer_contribution_amount = @plan_year.benefit_groups[0].estimated_monthly_employer_contribution
    @min_employee_cost = @plan_year.benefit_groups[0].estimated_monthly_min_employee_cost
    @max_employee_cost = @plan_year.benefit_groups[0].estimated_monthly_max_employee_cost
  end

  def edit
    plan_year = @employer_profile.find_plan_year(params[:id])
    @just_a_warning = false
    if plan_year.publish_pending?
      plan_year.withdraw_pending!
      if !plan_year.is_application_valid?
        @just_a_warning = true
        plan_year.application_eligibility_warnings.each_pair(){ |key, value| plan_year.errors.add(:base, value) }
      end
    end
    @plan_year = ::Forms::PlanYearForm.new(plan_year)
    @plan_year.benefit_groups.each do |benefit_group|
      case benefit_group.plan_option_kind
      when "metal_level"
        benefit_group.metal_level_for_elected_plan = benefit_group.elected_plans.try(:last).try(:metal_level)
      else
        benefit_group.carrier_for_elected_plan = benefit_group.elected_plans.try(:last).try(:carrier_profile_id)
      end
    end
  end

  def update
    plan_year = @employer_profile.plan_years.where(id: params[:id]).last
    @plan_year = ::Forms::PlanYearForm.rebuild(plan_year, plan_year_params)
    @plan_year.benefit_groups.each do |benefit_group|
      benefit_group.elected_plans = case benefit_group.plan_option_kind
                                    when "single_plan"
                                      Plan.where(id: benefit_group.reference_plan_id).first
                                    when "single_carrier"
                                      Plan.valid_shop_health_plans("carrier", benefit_group.carrier_for_elected_plan)
                                    when "metal_level"
                                      Plan.valid_shop_health_plans("metal_level", benefit_group.metal_level_for_elected_plan)
                                    end
    end
    if @plan_year.save
      flash[:notice] = "Plan Year successfully saved."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "edit"
    end
  end

  def recommend_dates
    if params[:start_on].present?
      start_on = params[:start_on].to_date
      @result = PlanYear.check_start_on(start_on)
      if @result[:result] == "ok"
        @open_enrollment_dates = PlanYear.calculate_open_enrollment_date(start_on)
        @schedule= PlanYear.shop_enrollment_timetable(start_on)
      end
    end
  end

  def publish
    @plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    @plan_year.publish!

    if @plan_year.publish_pending?
      respond_to do |format|
        format.js
      end
    else
      if (@plan_year.published? || @plan_year.enrolling?) 
        flash[:notice] = "Plan Year successfully published."
      else
        errors = @plan_year.application_errors.try(:values)
        flash[:error] = "Plan Year failed to publish. #{('<li>' + errors.join('</li><li>') + '</li>') if errors.try(:any?)}".html_safe
      end
      render :js => "window.location = #{employers_employer_profile_path(@employer_profile).to_json}"
    end
  end

  def force_publish
    plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    plan_year.force_publish!
    flash[:error] = "As submitted, this application is ineligible for coverage under the DC HealthLink exchange. If information that you provided leading to this determination is inaccurate, you have 30 days from this notice to request a review by DCHL officials."
    redirect_to employers_employer_profile_path(@employer_profile)
  end

  private

  def find_employer
    id_params = params.permit(:id, :employer_profile_id)
    id = id_params[:employer_profile_id] || id_params[:id]
    @employer_profile = EmployerProfile.find(id)
  end

  def generate_carriers_and_plans
    @carrier_names = Organization.valid_carrier_names
    @carriers_array = Organization.valid_carrier_names_for_options
  end

  def build_plan_year
    plan_year = PlanYear.new
    plan_year.benefit_groups.build
    ::Forms::PlanYearForm.new(plan_year)
  end

  def plan_year_params
    plan_year_params = params.require(:plan_year).permit(
      :start_on, :end_on, :fte_count, :pte_count, :msp_count,
      :open_enrollment_start_on, :open_enrollment_end_on,
      :benefit_groups_attributes => [ :id, :title, :reference_plan_id, :effective_on_offset,
                                      :carrier_for_elected_plan, :metal_level_for_elected_plan,
                                      :plan_option_kind, :employer_max_amt_in_cents, :_destroy,
                                      :relationship_benefits_attributes => [
                                        :id, :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
                                      ]
    ]
    )

    plan_year_params["benefit_groups_attributes"].delete_if {|k, v| v.count < 2 }
    plan_year_params
  end

  def relationship_benefits
    { 
      "benefit_groups_attributes" => 
      { 
        "0" => {
           "title"=>"2015 Employer Benefits",
           # "carrier_for_elected_plan"=>"53e67210eb899a4603000004",
           "reference_plan_id" => params[:reference_plan_id],
           "relationship_benefits_attributes" => params[:relation_benefits]
        }
      }
    }
  end
end

class Employers::PlanYearsController < ApplicationController
  before_action :find_employer, except: [:recommend_dates]
  before_action :generate_carriers_and_plans, except: [:recommend_dates]

  layout "two_column"

  def new
    @plan_year = build_plan_year
  end

  def reference_plans
    @benefit_group = params[:benefit_group]
    @plan_year = PlanYear.find(params[:plan_year_id])
    @location_id = params[:location_id]

    @plans = if params[:plan_option_kind] == "single_carrier"
      @carrier_id = params[:carrier_id]
      @carrier_profile = CarrierProfile.find(params[:carrier_id])
      Plan.by_active_year(params[:start_on]).shop_market.health_coverage.by_carrier_profile(@carrier_profile).and(hios_id: /-01/)
    elsif params[:plan_option_kind] == "metal_level"
      @metal_level = params[:metal_level]
      Plan.by_active_year(params[:start_on]).shop_market.health_coverage.by_metal_level(@metal_level).and(hios_id: /-01/)
    elsif params[:plan_option_kind] == "single_plan"
      @single_plan = params[:single_plan]
      @carrier_id = params[:carrier_id]
      @carrier_profile = CarrierProfile.find(params[:carrier_id])
      Plan.by_active_year(params[:start_on]).shop_market.health_coverage.by_carrier_profile(@carrier_profile).and(hios_id: /-01/)
    end

    @carriers_cache = CarrierProfile.all.inject({}){|carrier_hash, carrier_profile| carrier_hash[carrier_profile.id] = carrier_profile.legal_name; carrier_hash;}

    respond_to do |format|
      format.js
    end
  end

  def plan_details
    @plan = Plan.find(params[:reference_plan_id])
    respond_to do |format|
      format.js
    end
  end

  def make_default_benefit_group
    plan_year = @employer_profile.plan_years.where(_id: params[:plan_year_id]).first
    if plan_year && benefit_group = plan_year.benefit_groups.where(_id: params[:benefit_group_id]).first

      if default_benefit_group = @employer_profile.default_benefit_group
        return if benefit_group == default_benefit_group
        default_benefit_group.default = false
      end

      benefit_group.default = true
      begin
        @employer_profile.save!
      rescue => e
        message = "There was an error setting the default benefit group because the employer profile failed validation."
        message = message + " employer_profile: #{@employer_profile}"
        @employer_profile.plan_years.each do |plan_year|
          message = message + " plan_year: #{plan_year}" unless plan_year.valid?
        end
        message = message + " stacktrace: #{e.backtrace}"
        log(message, {:severity => "error"})
        raise e
      end
    end
  end

  def create
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    @plan_year.benefit_groups.each do |benefit_group|
      benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
    end

    if @employer_profile.default_benefit_group.blank?
      @plan_year.benefit_groups[0].default= true
    end

    if @plan_year.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile.id, :tab=>'benefits')
    else
      render action: "new"
    end
  end

  def reference_plan_options
    @kind = params[:kind]
    @key = params[:key]
    @target = params[:target]
    plan_year = Date.parse(params["start_date"]).year unless params["start_date"].blank?
    @plans = case @kind
            when "carrier"
              Plan.valid_shop_health_plans("carrier", @key, plan_year)
            when "metal-level"
              Plan.valid_shop_health_plans("metal_level", @key, plan_year)
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

    @employer_contribution_amount = @plan_year.benefit_groups[0].monthly_employer_contribution_amount
    @min_employee_cost = @plan_year.benefit_groups[0].monthly_min_employee_cost
    @max_employee_cost = @plan_year.benefit_groups[0].monthly_max_employee_cost
  end

  def calc_offered_plan_contributions
    @location_id = params[:location_id]
    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })

    @plan = Plan.find(params[:reference_plan_id])
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    @plan_year.benefit_groups[0].reference_plan = @plan

    @employer_contribution_amount = @plan_year.benefit_groups[0].monthly_employer_contribution_amount
    @min_employee_cost = @plan_year.benefit_groups[0].monthly_min_employee_cost
    @max_employee_cost = @plan_year.benefit_groups[0].monthly_max_employee_cost
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
      benefit_group.build_relationship_benefits if benefit_group.relationship_benefits.empty?
      case benefit_group.plan_option_kind
      when "metal_level"
        benefit_group.metal_level_for_elected_plan = benefit_group.elected_plans.try(:last).try(:metal_level)
      else
        benefit_group.carrier_for_elected_plan = benefit_group.elected_plans.try(:last).try(:carrier_profile_id)
      end
    end

    respond_to do |format|
      format.js { render 'edit' }
      format.html { render 'edit' }
    end
  end

  def update
    plan_year = @employer_profile.plan_years.where(id: params[:id]).last
    @plan_year = ::Forms::PlanYearForm.rebuild(plan_year, plan_year_params)
    @plan_year.benefit_groups.each do |benefit_group|
      benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
    end

    if @plan_year.save
      flash[:notice] = "Plan Year successfully saved."
      redirect_to employers_employer_profile_path(@employer_profile, :tab => "benefits")
    else
      redirect_to edit_employers_employer_profile_plan_year_path(@employer_profile, plan_year)
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

  def revert
    @plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    if @employer_profile.plan_years.renewing.include?(@plan_year) && @plan_year.may_revert_renewal?
      @plan_year.revert_renewal
      if @plan_year.save
        flash[:notice] = "Plan Year successfully reverted from renewing to applicant."
      else
        application_errors = @plan_year.application_errors
        errors = @plan_year.errors.full_messages
        error_messages = application_errors.inject(""){|memo, error| "#{memo}<li>#{error[0]}: #{error[1]}</li>"} +
                         errors.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}

        flash[:error] = "Renewing Plan Year could not be reverted to draft. #{error_messages}".html_safe
      end
    elsif @employer_profile.plan_years.include?(@plan_year) && @plan_year.may_revert_application?
      @plan_year.revert_application
      if @plan_year.save
        flash[:notice] = "Plan Year successfully reverted from published to applicant."
      else
        application_errors = @plan_year.application_errors
        errors = @plan_year.errors.full_messages
        error_messages = application_errors.inject(""){|memo, error| "#{memo}<li>#{error[0]}: #{error[1]}</li>"} +
                         errors.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}

        flash[:error] = "Published Plan Year could not be reverted to draft. #{error_messages}".html_safe
      end
    end
    render :js => "window.location = #{employers_employer_profile_path(@employer_profile, tab: 'benefits').to_json}"
  end

  def publish
    @plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    @plan_year.publish!
    if @plan_year.publish_pending?
      respond_to do |format|
        format.js
      end
    else
      if (@plan_year.published? || @plan_year.enrolling? || @plan_year.renewing_published? || @plan_year.renewing_enrolling?)
        if @plan_year.assigned_census_employees_without_owner.present?
          flash[:notice] = "Plan Year successfully published."
        else
          flash[:error] = "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?"
        end
      else
        errors = @plan_year.application_errors.try(:values)
        flash[:error] = "Plan Year failed to publish. #{('<li>' + errors.join('</li><li>') + '</li>') if errors.try(:any?)}".html_safe
      end
      render :js => "window.location = #{employers_employer_profile_path(@employer_profile, tab: 'benefits').to_json}"
    end
  end

  def force_publish
    plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    plan_year.force_publish!
    flash[:error] = "As submitted, this application is ineligible for coverage under the #{Settings.site.short_name} exchange. If information that you provided leading to this determination is inaccurate, you have 30 days from this notice to request a review by DCHL officials."
    redirect_to employers_employer_profile_path(@employer_profile, tab: 'benefits')
  end

  def employee_costs
    @location_id = params[:location_id]
    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })

    @plan = Plan.find(params[:reference_plan_id])
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    @plan_year.benefit_groups[0].reference_plan = @plan
    @plan_year.benefit_groups[0].plan_option_kind = params[:plan_option_kind]

    @benefit_group = @plan_year.benefit_groups[0]
    @benefit_group.set_bounding_cost_plans

    @benefit_group_costs = build_employee_costs_for_benefit_group
  end

  private

  def build_employee_costs_for_benefit_group
    employee_costs = @plan_year.employer_profile.census_employees.active.inject({}) do |census_employees, employee|
      costs = {
        ref_plan_cost: @benefit_group.employee_cost_for_plan(employee)
      }
      if !@benefit_group.single_plan_type?
        costs.merge!({
          lowest_plan_cost: @benefit_group.employee_cost_for_plan(employee, @benefit_group.lowest_cost_plan),
          highest_plan_cost: @benefit_group.employee_cost_for_plan(employee, @benefit_group.highest_cost_plan)
          })
      end
      census_employees[employee.id] = costs
      census_employees
    end
    employee_costs.merge!({
      ref_plan_employer_cost: @benefit_group.monthly_employer_contribution_amount,
      lowest_plan_employer_cost: @benefit_group.monthly_employer_contribution_amount(@benefit_group.lowest_cost_plan),
      highest_plan_employer_cost: @benefit_group.monthly_employer_contribution_amount(@benefit_group.highest_cost_plan)
      })
  end

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
    plan_year.benefit_groups.first.build_relationship_benefits
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

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
                                      @plan_year.carrier_plans_for(benefit_group.carrier_for_elected_plan)
                                    when "metal_level"
                                      @plan_year.metal_level_plans_for(benefit_group.metal_level_for_elected_plan)
                                    end
    end
    if @plan_year.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def search_reference_plan
    @location_id = params[:location_id]
    return unless params[:reference_plan_id].present?
    @plan = Plan.find(params[:reference_plan_id])
    @premium_tables = @plan.premium_tables.where(start_on: @plan.premium_tables.distinct(:start_on).max)
  end

  def edit
    @plan_year = ::Forms::PlanYearForm.new(@employer_profile.find_plan_year(params[:id]))
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
                                      @plan_year.carrier_plans_for(benefit_group.carrier_for_elected_plan)
                                    when "metal_level"
                                      @plan_year.metal_level_plans_for(benefit_group.metal_level_for_elected_plan)
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

    case
    when @plan_year.draft?
      flash[:notice] = "Plan Year failed to publish: #{@plan_year.application_errors}"
      redirect_to employers_employer_profile_path(@employer_profile)
    when @plan_year.publish_pending?
      # tell user bad idea
      flash[:notice] = "Publishing Plan Year is a bad idea because:: #{@plan_year.application_warnings}"
      redirect_to employers_employer_profile_path(@employer_profile)
    when @plan_year.published?
      flash[:notice] = "Plan Year successfully published"
      redirect_to employers_employer_profile_path(@employer_profile)
    end
  end

  private

  def find_employer
    id_params = params.permit(:id, :employer_profile_id)
    id = id_params[:employer_profile_id] || id_params[:id]
    @employer_profile = EmployerProfile.find(id)
  end

  def generate_carriers_and_plans
    @carriers = Organization.all.map{|o|o.carrier_profile}.compact.reject{|c| c.plans.where(active_year: Time.now.year, market: "shop", coverage_kind: "health").blank? }
  end

  def build_plan_year
    plan_year = PlanYear.new
    benefit_groups = plan_year.benefit_groups.build(plan_option_kind: nil)
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
    plan_year_params["benefit_groups_attributes"].delete_if {|k, v| v.count<2 } 
    plan_year_params
  end
end

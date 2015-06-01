class Employers::PlanYearsController < ApplicationController
  before_action :find_employer, except: [:recommend_dates]
  before_action :generate_carriers_and_plans, except: [:recommend_dates]

  def new
    @plan_year = build_plan_year
  end

  def create
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    @plan_year.benefit_groups.each do |benefit_group|
      reference_plan = benefit_group.reference_plan
      benefit_group.elected_plan_ids = reference_plan.carrier_profile.plans.where(active_year: 2015, market: "shop").collect(&:_id)
    end
    if @plan_year.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def recommend_dates
    if params[:start_on].present?
      start_on = Date.strptime(params[:start_on], "%m/%d/%Y").to_date
      @shop_enrollemnt_timetable = PlanYear.shop_enrollment_timetable(start_on)
    end
  end

  private

  def find_employer
    id_params = params.permit(:id, :employer_profile_id)
    id = id_params[:id] || id_params[:employer_profile_id]
    @employer_profile = EmployerProfile.find(id)
  end

  def generate_carriers_and_plans
    @carriers = Organization.all.map{|o|o.carrier_profile}.compact
  end

  def build_plan_year
    plan_year = PlanYear.new
    benefit_groups = plan_year.benefit_groups.build
    ::Forms::PlanYearForm.new(plan_year)
  end

  def plan_year_params
    #    new_params = format_date_params(params)
    params.require(:plan_year).permit(
      :start_on, :end_on, :fte_count, :pte_count, :msp_count,
      :open_enrollment_start_on, :open_enrollment_end_on,
      :benefit_groups_attributes => [ :title, :reference_plan_id, :effective_on_offset,
                                      :premium_pct_as_int, :employer_max_amt_in_cents, :_destroy,
                                      :relationship_benefits_attributes => [
                                        :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
                                      ]
    ]
    )
  end
end

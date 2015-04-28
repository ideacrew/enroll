class Employers::PlanYearsController < ApplicationController
  before_action :find_employer

  def new
    @plan_year = build_plan_year
  end

  def create
    @plan_year = PlanYear.new
    @plan_year.attributes = plan_year_params
    @employer_profile.plan_years << @plan_year
    if @employer_profile.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  private

  def find_employer
    id = params[:id] || params[:employer_profile_id]
    @employer_profile = EmployerProfile.find(id)
  end

  def build_plan_year
    plan_year = PlanYear.new
    benefit_groups = plan_year.benefit_groups.build
    relationship_benefits = benefit_groups.relationship_benefits.build
    plan_year
  end

  def plan_year_params
    new_params = format_date_params(params)
    new_params.require(:plan_year).permit(
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

  def format_date_params(params)
    ["start_on", "end_on", "open_enrollment_start_on", "open_enrollment_end_on"].each do |key|
      params["plan_year"][key] = Date.strptime(params["plan_year"][key], '%m/%d/%Y').to_s(:db)
    end

    params
  rescue Exception => e
    puts e
    params
  end
end

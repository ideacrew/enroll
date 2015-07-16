class Employers::PremiumStatementsController < ApplicationController

  def show
    employer_profile = EmployerProfile.find(params.require(:id))
    @current_plan_year = employer_profile.published_plan_year
    @enrolled_census_employees = @current_plan_year.enrolled
    @hbx_enrollments = @current_plan_year.hbx_enrollments
  end

end
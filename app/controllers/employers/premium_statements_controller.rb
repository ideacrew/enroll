class Employers::PremiumStatementsController < ApplicationController

  def show
    employer_profile = EmployerProfile.find(params.require(:id))
    @current_plan_year = employer_profile.published_plan_year
    @hbx_enrollments = @current_plan_year.hbx_enrollments rescue []
  end

end
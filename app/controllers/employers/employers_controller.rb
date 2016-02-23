class Employers::EmployersController < ApplicationController
  def search
    @employers = Organization.where(employer_profile: {:$exists=> true}, legal_name: /^#{params[:q]}/i)

    render json: @employers
  end

  def redirect_to_new
    redirect_to new_employers_employer_profile_path
  end
end

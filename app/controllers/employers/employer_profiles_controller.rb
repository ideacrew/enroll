class Employers::EmployerProfilesController < ApplicationController

  def index
    @employer_profiles = EmployerProfile.all.to_a
  end

end

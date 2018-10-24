class Employers::EmployerProfilesController < Employers::EmployersController

  before_action :redirect_new_model

  # This is to prevent any old model bookmarks from being accessed. It will redirect to new model.
  def redirect_new_model
    redirect_to "/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor"
  end


end

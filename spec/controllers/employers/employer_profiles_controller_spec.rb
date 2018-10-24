require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController, dbclean: :after_each do

  describe "Redirect to new model with status 302" do

  let(:user) { double("user")}

    it "should redirect with a 302" do
      get :index
      expect(response).to have_http_status(302)
    end

    it "should redirect to benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsors" do
      sign_in(user)
      get :index
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end
  end


end

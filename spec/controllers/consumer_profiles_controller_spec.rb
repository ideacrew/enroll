require "rails_helper"

describe ConsumerProfilesController do

  describe "GET home" do
    let(:user) { double(:person => person) }
    let(:person) { double(:primary_family => family, :employee_roles => employee_roles) }
    let(:family) {
      double(:active_family_members => [], :latest_household => latest_household)
    }
    let(:employee_roles) { [employee_role] }
    let(:employee_role) { }
    let(:latest_household) { double(:hbx_enrollments => []) }

    before(:each) do
      sign_in(user)
      get :home
    end

    it "should be successful" do
      expect(response).to have_http_status(:success)
    end
  end
end

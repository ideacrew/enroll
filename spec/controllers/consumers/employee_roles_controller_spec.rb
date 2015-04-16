require 'rails_helper'

RSpec.describe Consumer::EmployeeRolesController, :type => :controller do
  describe "GET welcome" do
    login_user

    before(:each) do
      get :welcome
    end

    it "renders the 'welcome' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("welcome")
    end
  end

  describe "GET new" do
    login_user

    before(:each) do
      get :new
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(assigns(:person)).to be_a_new(Person)
    end
  end
end

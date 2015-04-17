require 'rails_helper'

RSpec.describe Consumer::EmployeeRolesController, :type => :controller do
  describe "GET search" do

    before(:each) do
      sign_in
      get :search
    end

    it "renders the 'welcome' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns[:person]).to be_a(Forms::ConsumerIdentity)
    end
  end

  describe "GET welcome" do

    before(:each) do
      sign_in
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

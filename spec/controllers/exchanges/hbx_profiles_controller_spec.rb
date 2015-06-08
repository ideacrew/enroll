require 'rails_helper'

RSpec.describe Exchanges::HbxProfilesController do

  describe "Show" do
   let(:user) { double("user")}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
      get :show
    end

    it "renders 'show' " do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/show")
    end
  end

  describe "GET employer index" do
   let(:user) { double("user")}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
      get :employer_index
    end

    it "renders the 'employer index' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("employers/employer_profiles/index")
    end
  end

  describe "GET family index" do
    let(:user) { double("user")}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
      get :family_index
    end

    it "renders the 'famlies index' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("insured/families/index")
    end
  end

end

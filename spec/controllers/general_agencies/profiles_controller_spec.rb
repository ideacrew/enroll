require 'rails_helper'

RSpec.describe GeneralAgencies::ProfilesController do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }

  describe "GET new" do
    it "should redirect without login" do
      get :new
      expect(response).to have_http_status(:redirect)
    end

    it "should render the new template" do
      allow(controller).to receive(:check_general_agency_profile_permissions_new).and_return true
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
      expect(flash[:notice]).to eq "You don't have a General Agency Profile associated with your Account!! Please register your General Agency first."
      expect(response).to render_template("new")
    end
  end

  describe "GET index" do
    it "should redirect without login" do
      get :index
      expect(response).to have_http_status(:redirect)
    end

    it "should render the index template" do
      allow(controller).to receive(:check_general_agency_profile_permissions_index).and_return true
      sign_in(user)
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end
  end

  describe "GET new_agency" do
    it "should render the new_agency template" do
      get :new_agency
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new_agency")
    end

    it "should get organization" do
      get :new_agency
      expect(assigns(:organization).class).to eq Forms::GeneralAgencyProfile
    end
  end

  describe "GET new_agency_staff" do
    it "should render the new_agency_staff template" do
      get :new_agency_staff
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new_agency_staff")
    end

    it "should get organization" do
      get :new_agency_staff
      expect(assigns(:organization).class).to eq Forms::GeneralAgencyProfile
    end
  end

  describe "GET search_general_agency" do
    it "should returns http success" do
      xhr :get, :search_general_agency, general_agency_search: 'general_agency', format: :js
      expect(response).to have_http_status(:success)
    end

    it "should get general_agency_profile" do
      Organization.delete_all
      ga = FactoryGirl.create(:general_agency_profile)
      xhr :get, :search_general_agency, general_agency_search: ga.legal_name, format: :js
      expect(assigns[:general_agency_profiles]).to eq [ga]
    end
  end

  describe "GET show" do
    before(:each) do
      sign_in(user)
      get :show, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the show template" do
      expect(response).to render_template("show")
    end

    it "should get provider" do
      expect(assigns[:provider]).to eq person
    end

    it "should get staff_role" do
      expect(assigns[:staff_role]).to eq user.has_general_agency_staff_role?
    end
  end

  describe "GET employers" do
    before(:each) do
      sign_in(user)
      xhr :get, :employers, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the employers template" do
      expect(response).to render_template("employers")
    end

    it "should get employers" do
      expect(assigns[:employers]).to eq general_agency_profile.employer_clients
    end
  end

  describe "GET families" do
    before(:each) do
      sign_in(user)
      xhr :get, :families, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the families template" do
      expect(response).to render_template("families")
    end

    it "should get families" do
      expect(assigns[:families]).to eq general_agency_profile.family_clients
    end
  end

  describe "GET staffs" do
    before(:each) do
      sign_in(user)
      xhr :get, :staffs, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the staffs template" do
      expect(response).to render_template("staffs")
    end

    it "should get staffs" do
      expect(assigns[:staffs]).to eq general_agency_profile.general_agency_staff_roles
    end
  end
end

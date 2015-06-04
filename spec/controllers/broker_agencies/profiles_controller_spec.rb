require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesController do
  let(:broker_agency_profile_id) { "abecreded" }
  let(:plan_year_proxy) { double }
  let(:broker_agency_profile) { double("test") }

  describe "GET new" do
    let(:user) { double("user")}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_broker_role?)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show" do
    let(:user) { double("user")}
    let(:person) { double("person")}
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
    before(:each) do
      allow(user).to receive(:has_broker_role?)
      sign_in(user)
      get :show, id: broker_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the show template" do
      expect(response).to render_template("show")
    end
  end

  describe "GET index" do
    before :each do
      sign_in
      get :index
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end
  end

end
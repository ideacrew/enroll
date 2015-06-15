require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesController do
  let(:broker_agency_profile_id) { "abecreded" }
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

  describe "CREATE post" do
    let(:user){ double(:save => double("user")) }
    let(:person){ double(:broker_agency_contact => double("test")) }
    let(:broker_agency_profile){ double("test") }
    let(:form){double("test", :broker_agency_profile => broker_agency_profile)}
    let(:organization) {double("organization")}
    context "when no broker role" do
      before(:each) do
        allow(user).to receive(:has_broker_role?).and_return(false)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:person).and_return(person)
        sign_in(user)
        allow(Forms::BrokerAgencyProfile).to receive(:build).and_return(form)
      end

      it "returns http status" do
        allow(form).to receive(:save).and_return(true)
        post :create, organization: {}
        expect(response).to have_http_status(:redirect)
      end

      it "should render new template when invalid params" do
        allow(form).to receive(:save).and_return(false)
        post :create, organization: {}
        expect(response).to render_template("new")
      end
    end

  end

  describe "REDIRECT to my account if broker role present" do
    let(:user){double("user")}
    let(:person){double(:get_broker_profile_contact => double("person"))}

    it "should redirect to myaccount" do
      allow(user).to receive(:has_broker_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end

end

require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController do

  describe "GET new" do
    let(:user) { double("user")}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_employer_role?)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end

  end

  describe "GET search" do

    before(:each) do
      sign_in
      get :search
    end

    it "renders the 'search' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns[:employer_profile]).to be_a(Forms::EmployerCandidate)
    end
  end

  describe "GET index" do
    let(:organization_search_criteria) { double }
    let(:organization_employer_criteria) { double }
    let(:found_organization) { double(:employer_profile => employer) }
    let(:criteria_page_results) { [found_organization] }
    let(:employer) { double }
    let(:employer_list) { [employer] }

    before :each do
      sign_in
      allow(Organization).to receive(:search).with(nil).and_return(organization_search_criteria)
      allow(organization_search_criteria).to receive(:exists).with({employer_profile: true}).and_return(organization_employer_criteria)
      allow(organization_employer_criteria).to receive(:page).with(nil).and_return(criteria_page_results)
      get :index
    end

    it "assigns the list of employers" do
      expect(assigns(:employer_profiles)).to eq employer_list
    end

    it "returns http success" do 
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end
  end

  describe "GET index search" do
    let(:organization_search_criteria) { double }
    let(:organization_employer_criteria) { double }
    let(:found_organization) { double(:employer_profile => employer) }
    let(:criteria_page_results) { [found_organization] }
    let(:employer) { double }
    let(:employer_list) { [employer] }

    before :each do
      sign_in
      allow(Organization).to receive(:search).with("A Name").and_return(organization_search_criteria)
      allow(organization_search_criteria).to receive(:exists).with({employer_profile: true}).and_return(organization_employer_criteria)
      allow(organization_employer_criteria).to receive(:page).with(5).and_return(criteria_page_results)
      get :index, q: "A Name", page: 5
    end

    it "assigns the list of employers" do
      expect(assigns(:employer_profiles)).to eq employer_list
    end

    it "returns http success" do 
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end

  end

  describe "POST create" do
    let(:phone_attributes) { {
      :kind => "phone kind",
      :number => "phone number",
      :area_code => "area code",
      :extension => "extension"
    } }

    let(:email_attributes) { {
      :kind => "email",
      :address => "address"
    } } 
    let(:address_attributes) { {
      :kind => "address kind",
      :address_1 => "address 1",
      :address_2 => "address 2",
      :city => "city",
      :state => "MD",
      :zip => "22222"
    } }

    let(:organization_params) {
      {
        :employer_profile_attributes => {
          :entity_kind => "an entity kind",
          :dba => "a dba",
          :fein => "123456789",
          :legal_name => "a legal name"
        },
        :office_locations_attributes => {
          "0" => {
            :phone_attributes => phone_attributes,
            :email_attributes => email_attributes,
            :address_attributes => address_attributes
          }
        }
      }
    }

    let(:save_result) { false }

    let(:organization) { double }

    before(:each) do
      pending
      sign_in
      allow(Organization).to receive(:new).and_return(organization)
      allow(organization).to receive(:build_employer_profile)
      allow(organization).to receive(:attributes=).with(organization_params)
      allow(organization).to receive(:save).and_return(save_result)
      post :create, :organization => organization_params
    end

    describe "given an invalid employer profile" do
      it "assigns the organization" do
        expect(assigns(:organization)).to eq organization
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "renders the 'new' template" do
        expect(response).to render_template("new")
      end
    end

    describe "given a valid employer profile" do
      let(:save_result) { true }

      it "assigns the organization" do
        expect(assigns(:organization)).to eq organization
      end

      it "returns http redirect" do
        expect(response).to have_http_status(:redirect)
      end
    end

  end

end

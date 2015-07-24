require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController do

  describe "GET new" do
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false)}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_employer_staff_role?).and_return(false)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "REDIRECT to my account if employer staff role present" do
    let(:user) { double("user")}
    let(:person) { double(:employer_staff_roles => [double("person", :employer_profile_id => double)])}

    it "should render the new template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_employer_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET show" do
    let(:user) { double("user")}
    let(:person) { double("person")}
    let(:plan_year) { FactoryGirl.create(:plan_year) }
    let(:employer_profile) { plan_year.employer_profile}

    before(:each) do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_employer_staff_role?)
      employer_profile.plan_years = [plan_year]
      sign_in(user)
    end

    it "should render the show template" do
      get :show, id: employer_profile.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
      expect(assigns(:current_plan_year)).to eq employer_profile.published_plan_year
    end

    it "should get plan years" do
      get :show, id: employer_profile.id
      expect(assigns(:plan_years)).to eq employer_profile.plan_years.order(id: :desc)
      expect(assigns(:current_plan_year)).to eq employer_profile.published_plan_year
    end

    it "should get default status" do
      get :show, id: employer_profile.id
      expect(assigns(:status)).to eq "active"
    end

    it "should get 20 census_employees without page params" do
      30.times do
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, last_name: "#{('A'..'Z').to_a.sample}last_name")
      end
      get :show, id: employer_profile.id
      expect(assigns(:total_census_employees_quantity)).to eq employer_profile.census_employees.active.count
      expect(assigns(:census_employees).count).to eq 20
      expect(assigns(:census_employees)).to eq employer_profile.census_employees.active.sorted.search_by(employee_name: '').to_a.first(20)
    end

    it "search by employee name" do
      employer_profile.census_employees.delete_all
      census_employee = FactoryGirl.create(:census_employee, employer_profile: employer_profile)

      get :show, id: employer_profile.id, employee_name: census_employee.full_name 
      expect(assigns(:census_employees).count).to eq 1
      expect(assigns(:census_employees)).to eq [census_employee]
    end

    it "get avaliable_employee_names for autocomplete employee name" do
      get :show, id: employer_profile.id
      expect(assigns(:avaliable_employee_names)).to eq employer_profile.census_employees.sorted.map(&:full_name).uniq
    end
  end

  describe "GET welcome" do
    let(:user) { double("user")}

    it "renders the 'welcome' template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_employer_staff_role?)
      sign_in(user)
      get :welcome
      expect(response).to have_http_status(:success)
      expect(response).to render_template("welcome")
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
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      allow(Organization).to receive(:search).with(nil).and_return(organization_search_criteria)
      allow(organization_search_criteria).to receive(:exists).with({employer_profile: true}).and_return(organization_employer_criteria)
      allow(organization_employer_criteria).to receive(:where).and_return(criteria_page_results)
      allow(controller).to receive(:page_alphabets).and_return(["A", "B"])
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
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      allow(Organization).to receive(:search).with("A Name").and_return(organization_search_criteria)
      allow(organization_search_criteria).to receive(:exists).with({employer_profile: true}).and_return(organization_employer_criteria)
      allow(organization_employer_criteria).to receive(:where).and_return(criteria_page_results)
      allow(controller).to receive(:page_alphabets).and_return(["A", "B"])
      get :index, q: "A Name", page: "A"
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
          :entity_kind => "an entity kind",
          :dba => "a dba",
          :fein => "123456789",
          :legal_name => "a legal name",
        :office_locations_attributes => {
          "0" => {
            :phone_attributes => phone_attributes,
            :address_attributes => address_attributes
          }
        }
      }
    }

    let(:save_result) { false }

    let(:organization) { double(:employer_profile => double) }

    before(:each) do
      sign_in
      allow(Forms::EmployerProfile).to receive(:new).and_return(organization)
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

  describe "POST create" do
    let(:employer_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:found_employer) { double("test", :save => validation_result, :employer_profile => double) }
    let(:office_locations){[double(address: double("address"), phone: double("phone"), email: double("email"))]}
    let(:organization) {double(office_locations: office_locations)}

    before(:each) do
      sign_in
      allow(Forms::EmployerProfile).to receive(:new).and_return(found_employer)
#      allow(EmployerProfile).to receive(:find_by_fein).and_return(found_employer)
#      allow(found_employer).to receive(:organization).and_return(organization)
      post :create, :organization => employer_parameters
    end

    context "given invalid parameters" do
      let(:validation_result) { true }

      it "renders the 'edit' template" do
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "POST match" do
    let(:employer_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:found_employer) { [] }
    let(:create_employer_params) { "" }
    let(:mock_employer_candidate) { instance_double("Forms::EmployerCandidate", :valid? => validation_result) }

    before(:each) do
      sign_in
      allow(Forms::EmployerCandidate).to receive(:new).with(employer_parameters).and_return(mock_employer_candidate)
      allow(mock_employer_candidate).to receive(:match_employer).and_return(found_employer)
      post :match, :employer_profile => employer_parameters, :create_employer => create_employer_params
    end

    context "given invalid parameters" do
      let(:validation_result) { false }

      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:employer_profile]).to eq mock_employer_candidate
      end
    end

    context "given valid parameters render 'no_match' template" do
      let(:validation_result) { true }

      it "renders the 'no_match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("no_match")
        expect(assigns[:employer_candidate]).to eq mock_employer_candidate
      end
    end

    context "given valid parameters render 'match' template" do
      let(:validation_result) { true }
      let(:found_employer) { FactoryGirl.create(:employer_profile) }

      it "renders the 'match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns[:employer_candidate]).to eq mock_employer_candidate
        expect(assigns(:employer_profile)).to eq found_employer
      end
    end

    context "given valid parameters and create_employer" do
      let(:employer_parameters) { { :sic_code => "SOMDFINKETHING" } }
      let(:validation_result) { true }
      let(:create_employer_params) { true }

      it "renders the 'edit' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end
  end

  describe "PUT update" do
    let(:user) { double("user")}
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:organization) { FactoryGirl.create(:organization) }
    let(:person) { FactoryGirl.create(:person) }

    before do
      allow(user).to receive(:has_employer_staff_role?).and_return(true)
      allow(user).to receive(:roles).and_return(["employer_staff"])
      allow(user).to receive(:person).and_return(person)
      allow(Organization).to receive(:find).and_return(organization)
      allow(organization).to receive(:employer_profile).and_return(employer_profile)
      allow(controller).to receive(:employer_profile_params).and_return({})
    end

    it "should redirect" do
      allow(user).to receive(:save).and_return(true)
      allow(person).to receive(:employer_staff_roles).and_return([EmployerStaffRole.new])
      sign_in(user)
      expect(Organization).to receive(:find)
      expect(EmployerStaffRole).to receive(:create)
      expect(user).to receive(:roles)
      put :update, id: organization.id
      expect(response).to be_redirect
    end

    context "given current user is invalid" do
      it "should render edit template" do
        allow(user).to receive(:save).and_return(false)
        sign_in(user)
        put :update, id: organization.id
        expect(response).to render_template("edit")
      end
    end

     context "given the company has an owner" do
      it "should render edit template" do
        allow(employer_profile).to receive(:owner).and_return(person)
        allow(user).to receive(:save).and_return(true)
        sign_in(user)
        put :update, id: organization.id
        expect(response).to render_template("edit")
      end

    end



  end

  #describe "DELETE destroy" do
  #  let(:user) { double("user")}
  #  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  #  it "should redirect" do
  #    sign_in(user)
  #    expect {
  #      delete :destroy, id: employer_profile.id
  #    }.to change(EmployerProfile, :count).by(-1)
  #    expect(response).to be_redirect
  #  end
  #end
end

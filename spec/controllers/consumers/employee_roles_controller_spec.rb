require 'rails_helper'

RSpec.describe Consumer::EmployeeRolesController, :type => :controller do
  describe "PUT update" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:organization_id) { "1234324234" }
    let(:person_id) { "4324324234" }
    let(:benefit_group) { double }
    let(:census_employee) { double(:hired_on => "whatever" ) }
    let(:census_family) { double }
    let(:employer_profile) { double }
    let(:effective_date) { double }
    let(:person_id) { "5234234" }
    let(:role_form) {
      double(
             :organization_id => organization_id,
             :benefit_group => benefit_group,
             :census_employee => census_employee,
             :census_family => census_family,
             :employer_profile => employer_profile,
             :id => person_id)
    }

    before(:each) do
      sign_in
      allow(Forms::EmployeeRole).to receive(:find).with(person_id).and_return(role_form)
      allow(benefit_group).to receive(:effective_on_for).with("whatever").and_return(effective_date)
      allow(role_form).to receive(:update_attributes).with(person_parameters).and_return(save_result)
      put :update, :person => person_parameters, :id => person_id
    end

    describe "given valid person parameters" do
      let(:save_result) { true }

      it "should redirect to dependent_details" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("dependent_details")
      end
    end

    describe "given invalid person parameters" do
      let(:save_result) { false }

      it "should render match" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns(:person)).to eq role_form
        expect(assigns[:effective_on]).to eq effective_date
        expect(assigns[:benefit_group]).to eq benefit_group
        expect(assigns[:census_family]).to eq census_family
        expect(assigns[:employer_profile]).to eq employer_profile
      end
    end
  end
  describe "POST create" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:organization_id) { "1234324234" }
    let(:person_id) { "4324324234" }
    let(:benefit_group) { double }
    let(:census_employee) { double(:hired_on => "whatever" ) }
    let(:census_family) { double }
    let(:employer_profile) { double }
    let(:effective_date) { double }
    let(:role_form) {
      double(:save => save_result,
             :organization_id => organization_id,
             :benefit_group => benefit_group,
             :census_employee => census_employee,
             :census_family => census_family,
             :employer_profile => employer_profile,
             :id => person_id)
    }

    before(:each) do
      sign_in
      allow(Forms::EmployeeRole).to receive(:from_parameters).with(person_parameters).and_return(role_form)
      allow(benefit_group).to receive(:effective_on_for).with("whatever").and_return(effective_date)
      post :create, :person => person_parameters
    end

    describe "given valid person parameters" do
      let(:save_result) { true }

      it "should redirect to dependent_details" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("dependent_details")
      end
    end

    describe "given invalid person parameters" do
      let(:save_result) { false }

      it "should render match" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns(:person)).to eq role_form
        expect(assigns[:effective_on]).to eq effective_date
        expect(assigns[:benefit_group]).to eq benefit_group
        expect(assigns[:census_family]).to eq census_family
        expect(assigns[:employer_profile]).to eq employer_profile
      end
    end
  end

  describe "POST match" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => validation_result) }
    let(:hired_on) { double }
    let(:found_families) { [] }
    let(:employment_relationships) { double }

    before(:each) do
      sign_in 
      allow(Forms::EmployeeCandidate).to receive(:new).with(person_parameters).and_return(mock_employee_candidate)
      allow(EmployerProfile).to receive(:find_census_families_by_person).with(mock_employee_candidate).and_return(found_families)
      allow(Factories::EmploymentRelationshipFactory).to receive(:build).with(mock_employee_candidate, found_families).and_return(employment_relationships)
      post :match, :person => person_parameters
    end

    context "given invalid parameters" do
      let(:validation_result) { false }
      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
      end
    end

    context "given valid parameters" do
      let(:validation_result) { true }

      context "but with no found employee" do
        it "renders the 'no_match' template" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("no_match")
          expect(assigns[:employee_candidate]).to eq mock_employee_candidate
        end

        context "that find a matching employee" do
          let(:found_families) { [instance_double("EmployerCensus::EmployeeFamily")]} 

          it "renders the 'match' template" do
            expect(response).to have_http_status(:success)
            expect(response).to render_template("match")
            expect(assigns[:employee_candidate]).to eq mock_employee_candidate
            expect(assigns[:employment_relationships]).to eq employment_relationships
          end
        end
      end
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
      expect(assigns[:person]).to be_a(Forms::EmployeeCandidate)
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
end

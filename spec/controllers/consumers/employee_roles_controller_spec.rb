require 'rails_helper'

RSpec.describe Consumer::EmployeeRolesController, :type => :controller do
  describe "POST match" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:mock_consumer_identity) { instance_double("Forms::ConsumerIdentity", :valid? => validation_result) }
    let(:mock_service) { instance_double("Services::EmployeeSignupMatch") }
    let(:hired_on) { double }
    let(:mock_census_employee) { instance_double("EmployerCensus::Employee", :employee_family => mock_census_family, :hired_on => hired_on) }
    let(:mock_person) { instance_double("Person") }
    let(:mock_benefit_group) { instance_double("BenefitGroup") }
    let(:mock_census_family) { instance_double("EmployerCensus::EmployeeFamily", :benefit_group => mock_benefit_group, :employer_profile => mock_employer_profile) }
    let(:mock_employer_profile) { instance_double("EmployerProfile") }
    let(:effective_date) { double }
    let(:found_models) { nil }

    before(:each) do
      sign_in 
      allow(Forms::ConsumerIdentity).to receive(:new).with(person_parameters).and_return(mock_consumer_identity)
      allow(Services::EmployeeSignupMatch).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:call).with(mock_consumer_identity).and_return(found_models)
      allow(mock_benefit_group).to receive(:effective_on_for).with(hired_on).and_return(effective_date)
      post :match, :person => person_parameters
    end

    context "given invalid parameters" do
      let(:validation_result) { false }
      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:consumer_identity]).to eq mock_consumer_identity
      end
    end

    context "given valid parameters" do
      let(:validation_result) { true }

      context "but with no found employee" do
        it "renders the 'no_match' template" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("no_match")
          expect(assigns[:consumer_identity]).to eq mock_consumer_identity
        end

        context "that find a matching employee" do
          let(:found_models) { [mock_census_employee, mock_person] }

          it "renders the 'match' template" do
            expect(response).to have_http_status(:success)
            expect(response).to render_template("match")
            expect(assigns[:consumer_identity]).to eq mock_consumer_identity
            expect(assigns[:effective_on]).to eq effective_date
            expect(assigns[:benefit_group]).to eq mock_benefit_group
            expect(assigns[:census_family]).to eq mock_census_family
            expect(assigns[:employer_profile]).to eq mock_employer_profile
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
end

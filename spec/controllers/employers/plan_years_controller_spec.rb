require 'rails_helper'

RSpec.describe Employers::PlanYearsController do
  let(:employer_profile_id) { "abecreded" }
  let(:plan_year_proxy) { double }
  let(:employer_profile) { double(:plan_years => plan_year_proxy) }

  describe "GET new" do

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      get :new, :employer_profile_id => employer_profile_id
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the new template" do
      expect(response).to render_template("new")
    end

  end

  describe "POST create" do
    let(:save_result) { false }
    let(:plan) {double(:where => [double(:_id => "test")] )}
    let(:benefit_group){ double(:reference_plan => double(:carrier_profile => double(:plans => plan)))}
    let(:plan_year) { double(:benefit_groups => [benefit_group] ) }
    let(:relationship_benefits_attributes) {
      { "0" => {
         :relationship => "spouse",
         :premium_pct => "0.66",
         :employer_max_amt => "123.45",
         :offered => "false"
      } }
    }
    let(:benefit_groups_attributes) {
      { "0" => {
         :title => "My benefit group",
         :reference_plan_id => "rp_id", 
         :effective_on_offset => "e_on_offset",                      
         :elected_plan_kind => "plan",
         :plan_for_elected_plan => '12312',
        :employer_max_amt_in_cents => "2232",
        :relationship_benefits_attributes => relationship_benefits_attributes
      } }
    }

    let(:plan_year_params) {
      {
           :start_on => "01/01/2015",
           :end_on => "12/31/2015",
           :fte_count => "1",
           :pte_count => "3",
           :msp_count => "5",       
           :open_enrollment_start_on => "12/01/2014",
           :open_enrollment_end_on => "12/15/2014",
           :benefit_groups_attributes => benefit_groups_attributes
      }
    }

    let(:plan_year_request_params) {
      {
           :start_on => "01/01/2015",
           :end_on => "12/31/2015",
           :fte_count => 1,
           :pte_count => 3,
           :msp_count => 5,       
           :open_enrollment_start_on => "12/01/2014",
           :open_enrollment_end_on => "12/15/2014",
           :benefit_groups_attributes => benefit_groups_attributes
      }
    }

    before :each do
      sign_in
      allow(::Forms::PlanYearForm).to receive(:build).with(employer_profile, plan_year_params).and_return(plan_year)
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(benefit_group).to receive(:elected_plan_ids=).and_return("test")
      allow(benefit_group).to receive(:elected_plan_kind).and_return("plan")
      allow(benefit_group).to receive(:plan_for_elected_plan).and_return(FactoryGirl.create(:plan).id)
      allow(plan_year).to receive(:save).and_return(save_result)
      post :create, :employer_profile_id => employer_profile_id, :plan_year => plan_year_request_params
    end

    describe "with an invalid plan year" do
      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("new")
      end

      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end
    end

    describe "with a valid plan year" do
      let(:save_result) { true }

      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end

      it "should be a redirect" do
        expect(response).to have_http_status(:redirect)
      end
    end

  end

  describe "GET recommend_dates" do
    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      xhr :get, :recommend_dates, employer_profile_id: employer_profile_id, start_on: "2015-05-10", format: :js
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end
  end
end

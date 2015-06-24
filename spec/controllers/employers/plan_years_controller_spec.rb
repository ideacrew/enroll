require 'rails_helper'

RSpec.describe Employers::PlanYearsController do
  let(:employer_profile_id) { EmployerProfile.new.id}
  let(:plan_year_proxy) { double(id: "id") }
  let(:employer_profile) { double(:plan_years => plan_year_proxy, find_plan_year: plan_year_proxy) }

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

    it "should generate carriers" do
      expect(assigns(:carriers)).to eq Organization.all.map{|o|o.carrier_profile}.compact.reject{|c| c.plans.where(active_year: Time.now.year, market: "shop", coverage_kind: "health").blank? }
    end
  end

  describe "GET edit" do

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      get :edit, :employer_profile_id => employer_profile_id, id: plan_year_proxy.id
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the edit template" do
      expect(response).to render_template("edit")
    end

    it "should generate carriers" do
      expect(assigns(:carriers)).to eq Organization.all.map{|o|o.carrier_profile}.compact.reject{|c| c.plans.where(active_year: Time.now.year, market: "shop", coverage_kind: "health").blank? }
    end
  end

  describe "POST update" do
    let(:save_result) { false }
    let(:plan) {double(:where => [double(:_id => "test")] )}
    let(:benefit_group){ double(:reference_plan => double(:carrier_profile => double(:plans => plan)))}
    let(:plan_year) { double(:benefit_groups => [benefit_group], id: "id" ) }
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
         :plan_option_kind => "single_plan",
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
      allow(benefit_group).to receive(:elected_plans=).and_return("test")
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      #allow(benefit_group).to receive(:reference_plan_id).and_return(FactoryGirl.create(:plan).id)
      allow(benefit_group).to receive(:reference_plan_id).and_return(nil)
      allow(plan_year).to receive(:save).and_return(save_result)
      post :update, :employer_profile_id => employer_profile_id, id: plan_year.id, :plan_year => plan_year_request_params
    end

    describe "with an invalid plan year" do
      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("edit")
      end

      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end

      it "should generate carriers" do
        expect(assigns(:carriers)).to eq Organization.all.map{|o|o.carrier_profile}.compact.reject{|c| c.plans.where(active_year: Time.now.year, market: "shop", coverage_kind: "health").blank? }
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

      it "should has successful notice" do
        expect(flash[:notice]).to eq "Plan Year successfully saved."
      end
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
         :plan_option_kind => "single_plan",
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
      allow(benefit_group).to receive(:elected_plans=).and_return("test")
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      #allow(benefit_group).to receive(:reference_plan_id).and_return(FactoryGirl.create(:plan).id)
      allow(benefit_group).to receive(:reference_plan_id).and_return(nil)
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

      it "should generate carriers" do
        expect(assigns(:carriers)).to eq Organization.all.map{|o|o.carrier_profile}.compact.reject{|c| c.plans.where(active_year: Time.now.year, market: "shop", coverage_kind: "health").blank? }
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

      it "should has successful notice" do
        expect(flash[:notice]).to eq "Plan Year successfully created."
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

  describe "POST publish" do
    let(:plan_year_id) { "plan_year_id"}
    let(:plan_year_proxy) { instance_double("PlanYear", publish: double)}

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
    end

    context "plan year published sucessfully" do
      before :each do
        allow(plan_year_proxy).to receive(:save).and_return(true)
      end

      it "should be a redirect" do
        post :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(response).to have_http_status(:redirect)
      end
    end

    context "plan year did not publish" do
      before :each do
        allow(plan_year_proxy).to receive(:save).and_return(false)
        allow(plan_year_proxy).to receive(:application_warnings)
      end

      it "should be a redirect with warnings" do
        post :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(response).to have_http_status(:redirect)
      end
    end

  end
end

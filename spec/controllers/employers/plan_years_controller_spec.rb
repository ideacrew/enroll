require 'rails_helper'

RSpec.describe Employers::PlanYearsController do
  let(:employer_profile_id) { EmployerProfile.new.id}
  let(:plan_year_proxy) { double(id: "id") }
  let(:employer_profile) { double(:plan_years => plan_year_proxy, find_plan_year: plan_year_proxy) }

  describe "GET new" do

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(Organization).to receive(:valid_carrier_names).and_return({id: "legal_name"})
      get :new, :employer_profile_id => employer_profile_id
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the new template" do
      expect(response).to render_template("new")
    end

    it "should generate carriers" do
      expect(assigns(:carrier_names)).to eq({id: "legal_name"})
    end

    it "should generate benefit_group with nil plan_option_kind" do
      benefit_group = assigns(:plan_year).benefit_groups.first
      expect(benefit_group.plan_option_kind).to eq nil
    end
  end

  describe "GET calc_employer_contributions" do
    let(:employer_profile){ double("EmployerProfile") }
    let(:reference_plan){ FactoryGirl.create(:plan) }
    let(:plan_years){ [double("PlanYear")] }
    let(:benefit_groups){ [
      double(
        "BenefitGroup",
        estimated_monthly_employer_contribution: 56.2,
        estimated_monthly_min_employee_cost: 200.21,
        estimated_monthly_max_employee_cost: 500.32
        )] }
    let(:plan){ double("Plan") }
    it "should calculate employer contributions" do
      allow(EmployerProfile).to receive(:find).with("id").and_return(employer_profile)
      allow(Forms::PlanYearForm).to receive(:build).and_return(plan_years.first)
      allow(plan_years.first).to receive(:benefit_groups).and_return(benefit_groups)
      allow(benefit_groups.first).to receive(:reference_plan=).and_return(plan)
      sign_in
      xhr :get, :calc_employer_contributions, employer_profile_id: "id", reference_plan_id: reference_plan.id
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit" do
    let(:plan_year) {FactoryGirl.build(:plan_year)}

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:find_plan_year).and_return(plan_year)
      allow(Organization).to receive(:valid_carrier_names).and_return({id: "legal_name"})
    end

    context "when draft state" do
      before :each do
        get :edit, :employer_profile_id => employer_profile_id, id: plan_year_proxy.id
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the edit template" do
        expect(response).to render_template("edit")
      end

      it "should generate carriers" do
        expect(assigns(:carrier_names)).to eq({id: "legal_name"})
      end
    end


    context "when publish pending state" do
      let(:warnings) { { primary_location: "primary location is outside washington dc" } }

      before :each do
        allow(plan_year).to receive(:publish_pending?).and_return(true)
        allow(plan_year).to receive(:withdraw_pending!)
        allow(plan_year).to receive(:is_application_valid?).and_return(false)
        allow(plan_year).to receive(:application_eligibility_warnings).and_return(warnings)
        get :edit, :employer_profile_id => employer_profile_id, id: plan_year_proxy.id
      end

      it "should set warnings flag" do
        expect(assigns(:just_a_warning)).to eq(true)
      end

      it "should set errors" do
        expect(plan_year.errors[:base]).to eq ["primary location is outside washington dc"]
      end
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
    let(:plan_years) {double}

    before :each do
      sign_in
      allow(::Forms::PlanYearForm).to receive(:rebuild).with(plan_year, plan_year_params).and_return(plan_year)
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return(plan_years)
      allow(plan_years).to receive(:where).and_return([plan_year])
      allow(benefit_group).to receive(:elected_plans=).and_return("test")
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      #allow(benefit_group).to receive(:reference_plan_id).and_return(FactoryGirl.create(:plan).id)
      allow(benefit_group).to receive(:reference_plan_id).and_return(nil)
      allow(plan_year).to receive(:save).and_return(save_result)
      allow(Organization).to receive(:valid_carrier_names).and_return({id: "legal_name"})
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
        expect(assigns(:carrier_names)).to eq({id: 'legal_name'})
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
      allow(Organization).to receive(:valid_carrier_names).and_return({id: "legal_name"})
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
        expect(assigns(:carrier_names)).to eq({id: 'legal_name'})
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

  describe "GET reference_plan_options" do
    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
    end

    it "should be a success" do
      xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'carrier', format: :js
      expect(response).to have_http_status(:success)
    end

    it "should got attributes" do
      xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'carrier', key: 'carrier_profile_id', format: :js
      expect(assigns(:kind)).to eq 'carrier'
      expect(assigns(:key)).to eq 'carrier_profile_id'
    end
  end

  describe "POST publish" do
    let(:plan_year_id) { "plan_year_id"}
    let(:plan_year_proxy) { instance_double("PlanYear", publish!: double)}

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(plan_year_proxy).to receive(:draft?).and_return(false)
      allow(plan_year_proxy).to receive(:publish_pending?).and_return(false)
      allow(plan_year_proxy).to receive(:application_errors)
    end

    context "plan year published sucessfully" do
      before :each do
        allow(plan_year_proxy).to receive(:published?).and_return(true)
      end

      it "should redirect with success message" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:notice]).to eq "Plan Year successfully published."
      end
    end

    context "plan year did not publish due to warnings" do
      before :each do
        allow(plan_year_proxy).to receive(:publish_pending?).and_return(true)
        allow(plan_year_proxy).to receive(:application_eligibility_warnings)
      end

      it "should be a render modal box with warnings" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        have_http_status(:success)
      end
    end

    context "plan year did not publish due to errors" do
      before :each do
        allow(plan_year_proxy).to receive(:draft?).and_return(true)
        allow(plan_year_proxy).to receive(:published?).and_return(false)
        allow(plan_year_proxy).to receive(:enrolling?).and_return(false)
      end

      it "should redirect with errors" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:error]).to match(/Plan Year failed to publish/)
      end
    end
  end

  describe "POST force publish" do
    let(:plan_year_id) { "plan_year_id"}
    let(:plan_year_proxy) { instance_double("PlanYear", publish!: double)}

    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(plan_year_proxy).to receive(:force_publish!)
      post :force_publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
    end

    it "should redirect" do
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET search_reference_plan" do
    let(:plan) {FactoryGirl.create(:plan)}
    before :each do
      sign_in
      xhr :get, :search_reference_plan, employer_profile_id: employer_profile_id, location_id: "test", reference_plan_id: plan.id, format: :js
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should be get location_id" do
      expect(assigns(:location_id)).to eq "test"
    end

    it "should be get plan" do
      expect(assigns(:plan)).to eq plan
    end
  end
end

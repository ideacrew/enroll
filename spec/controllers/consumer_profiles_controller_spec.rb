require 'rails_helper'

RSpec.describe ConsumerProfilesController, :type => :controller do
  let(:plan) { double }
  let(:hbx_enrollment) { double }
  let(:hbx_enrollments) { double }
  let(:benefit_group) { double("BenefitGroup") }
  let(:reference_plan) { double }
  let(:usermailer) { double("UserMailer") }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user) }
  let(:family) { double("Family") }
  let(:household) { double("HouseHold") }
  let(:plan_year) { double("PlanYear") }
  let(:family_members){[double("FamilyMember")]}

  context "GET home" do
    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:active_family_members).and_return(family_members)
      allow(family).to receive(:latest_household).and_return(household)
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:active).and_return(hbx_enrollments)
    end

    it "should return success" do
      sign_in user
      get :home
      expect(response).to have_http_status(:success)
    end
  end

  context "GET personal" do
    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:active_family_members).and_return(family_members)
    end
    it "should return success" do
      sign_in user
      get :personal
      expect(response).to have_http_status(:success)
    end
  end

  context "GET family" do
    let(:employee_roles){ [double("EmployeeRole")] }
    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:active_family_members).and_return(family_members)
      allow(person).to receive(:employee_roles).and_return(employee_roles)
    end
    it "should return success" do
      sign_in user
      get :family
      expect(response).to have_http_status(:success)
    end
  end

  context "GET inbox" do
    it "should return success" do
      sign_in user
      xhr :get, :inbox
      expect(response).to have_http_status(:success)
    end
  end

  context "retrieve plan" do
    let(:qhp){double("Products::Qhp")}
    let(:qhp_benefits){double("Products::QhpBenefit")}
    let(:plan) { double(hios_id: "11100000001100") }
    let(:benefit_group_assignment) { double(coverage_waived?: true) }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:latest_household).and_return(household)
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:active).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:last).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:plan).and_return(plan)
      allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
      allow(Products::Qhp).to receive(:find_by).and_return(qhp)
      allow(qhp).to receive(:qhp_benefits).and_return(qhp_benefits)

      sign_in user
      get :plans
    end

    it "returns the enrolled plan of the user" do
      expect(response).to have_http_status(:success)
    end

    it "return benefit_group_assignment" do
      expect(assigns(:benefit_group_assignment)).to eq benefit_group_assignment
    end
  end

  context "get purchase" do
    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:latest_household).and_return(household)
      allow(family).to receive(:is_eligible_to_enroll?).and_return(true)
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:active).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:plan=).with(plan).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(:reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:select_coverage!).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(double)
    end

    it "returns http success" do
      sign_in user
      get :purchase
      expect(response).to have_http_status(:success)
    end

    it "redirect when has no hbx_enrollment" do
      allow(hbx_enrollments).to receive(:active).and_return([])
      request.env["HTTP_REFERER"] = "/"
      sign_in user
      get :purchase
      expect(response).to have_http_status(:redirect)
    end

    it "return enrollable" do
      sign_in user
      get :purchase
      expect(assigns(:enrollable)).to eq true
    end
  end
end

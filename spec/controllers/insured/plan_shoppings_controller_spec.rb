require 'rails_helper'

RSpec.describe Insured::PlanShoppingsController, :type => :controller do
  let(:plan) { double }
  let(:hbx_enrollment) { double }
  let(:benefit_group) {double}
  let(:reference_plan) {double}
  let(:usermailer) {double}
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:employee_role) { EmployeeRole.new }

  context "POST checkout" do
    before do
      allow(Plan).to receive(:find).with("plan_id").and_return(plan)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:plan=).with(plan).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(:reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:select_coverage!).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(UserMailer).to receive(:plan_shopping_completed).and_return(usermailer)
      allow(usermailer).to receive(:deliver_now).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      allow(employee_role).to receive(:hired_on).and_return(TimeKeeper.date_of_record + 10.days)
    end

    it "returns http success" do
      sign_in
      post :checkout, id: "hbx_id", plan_id: "plan_id"
      expect(response).to have_http_status(:redirect)
    end

    context "employee hire_on date greater than enrollment date" do
      it "fails" do
        sign_in
        post :checkout, id: "hbx_id", plan_id: "plan_id"
        expect(flash[:error]).to include("You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance")
      end
    end
  end

  context "POST terminate" do
    before do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:terminate_coverage!).and_return(true)
      sign_in
      post :terminate, id: "hbx_id"
    end

    it "returns http success" do
      expect(response).to be_redirect
    end
  end

  context "POST waive" do
    before :each do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:shopping?).and_return(true)
      sign_in user
    end

    it "should get success flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:waive_coverage).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("waiver").and_return(true)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:notice]).to eq "Waive Successful"
      expect(response).to be_redirect
    end

    it "should get failure flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(false)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:alert]).to eq "Waive Failure"
      expect(response).to be_redirect
    end
  end
end

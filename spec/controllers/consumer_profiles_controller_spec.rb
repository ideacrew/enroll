require 'rails_helper'

RSpec.describe ConsumerProfilesController, :type => :controller do
  let(:plan) { double }
  let(:hbx_enrollment) { double }
  let(:hbx_enrollments) { double }
  let(:benefit_group) {double}
  let(:reference_plan) {double}
  let(:usermailer) {double}
  let(:person) {FactoryGirl.create(:person)}
  let(:user) {FactoryGirl.create(:user)}
  let(:family) {double}
  let(:household) {double}
  let(:plan_year) {double}

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
      allow(benefit_group).to receive(:plan_year).and_return(plan_year)
      allow(plan_year).to receive(:is_eligible_to_enroll?).and_return(true)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:select_coverage!).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
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
  end
end

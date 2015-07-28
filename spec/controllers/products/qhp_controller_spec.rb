require 'rails_helper'

RSpec.describe Products::QhpController, :type => :controller do
  let(:user) { double("User") }
  let(:person) { double("Person")}
  let(:hbx_enrollment){double("HbxEnrollment")}
  let(:benefit_group){double("BenefitGroup")}
  let(:reference_plan){double("Plan")}
  context "GET comparison" do
    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
    end
    it "should return comparison of multiple plans" do
      sign_in(user)
      get :comparison, standard_component_ids: ["11111111111111"]
      expect(response).to have_http_status(:success)
    end
  end

  context "GET summary" do
    let(:hbx_enrollment){ double("HbxEnrollment", id: double("id")) }
    let(:benefit_group){ double("BenefitGroup") }
    let(:reference_plan){ double("Plan") }
    let(:qhp) { [double("Qhp", plan: double("Plan"))] }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(Products::Qhp).to receive(:where).with({standard_component_id: "11111100001111"}).and_return(qhp)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
    end
    it "should return summary of a plan" do
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id
      expect(response).to have_http_status(:success)
    end
  end
end

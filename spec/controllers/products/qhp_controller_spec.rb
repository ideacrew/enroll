require 'rails_helper'

RSpec.describe Products::QhpController, :type => :controller do
  let(:user) { double("User", person: person) }
  let(:person) { double("Person", primary_family: family)}
  let(:hbx_enrollment){double("HbxEnrollment", kind: "shop")}
  let(:benefit_group){double("BenefitGroup")}
  let(:reference_plan){double("Plan")}
  let(:tax_household) {double}
  let(:household) {double(tax_households: [tax_household])}
  let(:family) {double(latest_household: household)}
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
    let(:hbx_enrollment){ double("HbxEnrollment", id: double("id"), kind: "shop") }
    let(:benefit_group){ double("BenefitGroup") }
    let(:reference_plan){ double("Plan") }
    let(:qhp) { [double("Qhp", plan: double("Plan"))] }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(Products::Qhp).to receive(:by_hios_id_and_active_year).and_return(qhp)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
    end
    it "should return summary of a plan" do
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id, active_year: "2015"
      expect(response).to have_http_status(:success)
    end
  end

  context "GET comparison when get more than one qhp" do
    let(:hbx_enrollment){ HbxEnrollment.new }
    let(:benefit_group){ double("BenefitGroup") }
    let(:reference_plan){ double("Plan") }
    let(:qhp1) { Products::Qhp.new }
    let(:qhp2) { Products::Qhp.new }
    let(:plan1) { double("Plan", hios_id: "11111100001111-01") }
    let(:plan2) { double("Plan", hios_id: "11111100001111") }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(Products::Qhp).to receive(:where).and_return([qhp1, qhp2])
      allow(qhp1).to receive(:plan).and_return plan1
      allow(qhp2).to receive(:plan).and_return plan2
      allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_employee_cost: 100))
    end
    it "should return comparison of a plan" do
      sign_in(user)
      get :comparison, standard_component_ids: ["11111100001111-01"], hbx_enrollment_id: hbx_enrollment.id, coverage_kind: 'individual'
      expect(response).to have_http_status(:success)
      expect(assigns(:qhps).count).to eq 1
    end
  end
end

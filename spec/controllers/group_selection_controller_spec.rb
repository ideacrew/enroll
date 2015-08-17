require 'rails_helper'

RSpec.describe GroupSelectionController, :type => :controller do
  let(:person) {FactoryGirl.create(:person)}
  let(:employee_role) {FactoryGirl.create(:employee_role)}
  let(:household) {double(:immediate_family_coverage_household=> coverage_household, :hbx_enrollments => hbx_enrollments)}
  let(:coverage_household) {double}
  let(:family) {Family.new}
  let(:hbx_enrollment) {HbxEnrollment.create}
  let(:hbx_enrollments) {double(:active => [hbx_enrollment])}

  before do
    allow(Person).to receive(:find).and_return(person)
    allow(person).to receive(:primary_family).and_return(family)
    allow(family).to receive(:active_household).and_return(household)
  end

  context "GET new" do
    it "return http success" do
      sign_in
      get :new, person_id: person.id, employee_role_id: employee_role.id
      expect(response).to have_http_status(:success)
    end

    it "return blank change_plan" do
      sign_in
      get :new, person_id: person.id, employee_role_id: employee_role.id
      expect(assigns(:change_plan)).to eq ""
    end

    it "return change_plan" do
      sign_in
      get :new, person_id: person.id, employee_role_id: employee_role.id, change_plan: "change"
      expect(assigns(:change_plan)).to eq "change"
    end
  end

  context "POST CREATE" do
    let(:family_member_ids) {{"0"=>"559366ca63686947784d8f01", "1"=>"559366ca63686947784e8f01", "2"=>"559366ca63686947784f8f01", "3"=>"559366ca6368694778508f01"}}
    let(:benefit_group) {FactoryGirl.create(:benefit_group)}
    let(:benefit_group_assignment) {double(update: true)}
    let(:employee_roles){ [double("EmployeeRole")] }

    before do
      allow(coverage_household).to receive(:household).and_return(household)
      allow(household).to receive(:new_hbx_enrollment_from).and_return(hbx_enrollment)
      allow(person).to receive(:employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:rebuild_members_by_coverage_household).with(coverage_household: coverage_household).and_return(true)
      allow(family).to receive(:latest_household).and_return(household)
      allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
      allow(hbx_enrollment).to receive(:inactive_related_hbxs).and_return(true)
      sign_in
    end

    it "should redirect" do
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: hbx_enrollment.id, market_kind: 'shop', coverage_kind: 'health'))
    end

    it "with change_plan" do
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, change_plan: 'change'
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: hbx_enrollment.id, change_plan: 'change', coverage_kind: 'health', market_kind: 'shop'))
    end

    it "when keep_existing_plan" do
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:plan=).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, commit: 'Keep existing plan', change_plan: 'change'
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(purchase_consumer_profiles_path(change_plan:'change', coverage_kind: 'health', market_kind:'shop'))
    end

    it "should render group selection page if not valid" do
      allow(person).to receive(:employee_roles).and_return([employee_role])
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(group_selection_new_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop'))
    end

  end
end

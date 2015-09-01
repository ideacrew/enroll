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

  context "GET terminate_selection" do
    it "return http success and render" do
      sign_in
      get :terminate_selection, person_id: person.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:terminate_selection)
    end
  end

  context "GET terminate_confirm" do
    it "return http success and render" do
      sign_in
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      get :terminate_confirm, person_id: person.id, hbx_enrollment_id: hbx_enrollment.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:terminate_confirm)
    end
  end

  context "POST terminate" do

    before do
      sign_in
      request.env["HTTP_REFERER"] = group_selection_terminate_confirm_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
    end

    it "should redirect to family home if termination is possible" do
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:update_current)
      expect(hbx_enrollment).to receive(:propogate_terminate).with(Date.today)
      post :terminate, term_date: Date.today, hbx_enrollment_id: hbx_enrollment.id
      expect(response).to redirect_to(family_account_path)
    end

    it "should redirect back if hbx enrollment can't be terminated" do
      post :terminate, term_date: Date.today, hbx_enrollment_id: hbx_enrollment.id
      expect(hbx_enrollment.may_terminate_coverage?).to be_falsey
      expect(response).to redirect_to(group_selection_terminate_confirm_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id))
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
      user=FactoryGirl.create(:user, id: 99, person: person)
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: hbx_enrollment.id, market_kind: 'shop', coverage_kind: 'health'))
    end

    it "with change_plan" do
      user = FactoryGirl.create(:user, id: 98, person: FactoryGirl.create(:person))
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, change_plan: 'change'
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: hbx_enrollment.id, change_plan: 'change', coverage_kind: 'health', market_kind: 'shop'))
    end

    it "when keep_existing_plan" do
      user = FactoryGirl.create(:user, id: 97, person: FactoryGirl.create(:person))
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:plan=).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, commit: 'Keep existing plan', change_plan: 'change'
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(purchase_consumer_profiles_path(change_plan:'change', coverage_kind: 'health', market_kind:'shop'))
    end

    it "should render group selection page if not valid" do
      user = FactoryGirl.create(:user, id: 96, person: FactoryGirl.create(:person))
      sign_in user
      allow(person).to receive(:employee_roles).and_return([employee_role])
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq 'You must select the primary applicant to enroll in the healthcare plan'
      expect(response).to redirect_to(group_selection_new_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop', return_action: 'group_create'))
    end

    it "should render group selection page if without family_member_ids" do
      post :create, person_id: person.id, employee_role_id: employee_role.id
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq 'You must select at least one applicant to enroll in the healthcare plan'
      expect(response).to redirect_to(group_selection_new_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop', return_action: 'group_create'))
    end
  end
end

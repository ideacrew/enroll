require 'rails_helper'

RSpec.describe "insured/families/home.html.erb" do
  let(:current_user) {FactoryBot.create(:user)} #let(:person) { FactoryBot.create(:person, :with_family ) }
  let(:person_employee) { FactoryGirl.create(:person, :with_employee_role, :with_family)} #let(:person) { FactoryGirl.create(:person, :with_family ) }
  let(:person_hbx) { FactoryGirl.create(:person, :with_hbx_staff_role, :with_family)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_family, :with_hbx_staff_role) }
  let(:user_with_employer_role) { FactoryGirl.create(:user, :with_family, :employer_staff) }
  let(:hbx_staff_permission) { FactoryGirl.create(:permission, :hbx_staff) }
  let(:current_user) {FactoryBot.create(:user,person:person)}

  let(:qle_first_of_month) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_first_of_month, ) }
  let(:sep){
    sep = family.special_enrollment_periods.new
    sep.effective_on_kind = 'first_of_month'
    sep.qualifying_life_event_kind= qle_first_of_month
    sep.qualifying_life_event_kind_id = qle_first_of_month.id
    sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
    sep.admin_flag = true
    sep
  }
  let(:hbx) { HbxEnrollment.new(created_at: TimeKeeper.date_of_record, effective_on: TimeKeeper.date_of_record, family: family) }
  let(:term_hbx) { HbxEnrollment.new(created_at: TimeKeeper.date_of_record, effective_on: TimeKeeper.date_of_record, aasm_state: "coverage_terminated", family: family) }

  before :each do
    stub_template "insured/families/_right_column.html.erb" => ''
    stub_template "insured/families/_qle_detail.html.erb" => ''
    stub_template "insured/families/_enrollment.html.erb" => ''
    stub_template "insured/families/_navigation.html.erb" => ''
    stub_template "insured/families/_shop_for_plans_widget.html.erb" => ''
    stub_template "insured/families/_apply_for_medicaid_widget.html.erb" => ''
    stub_template "app/views/ui-components/v1/modals/_help_with_plan.html.slim" => ''
    assign(:person, person)
    sign_in current_user
    assign(:person, person_employee)
    allow(view).to receive(:current_user).and_return(user_with_employer_role)
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", can_view_entire_family_enrollment_history?: true))
    assign(:family, family)
    render file: "insured/families/home.html.erb"
  end

  it "should display the title" do
    render file: "insured/families/home.html.erb"
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('h1', text: "My #{Settings.site.short_name}")
  end

  it "should have plan-summary area" do
    render file: "insured/families/home.html.erb"
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('div#plan-summary')
  end

  it "should display 'existing SEP - Eligible to enroll' partial if there is an active admin SEP" do
    render file: "insured/families/home.html.erb"
    assign(:active_sep, sep)
    render file: "insured/families/home.html.erb"
    expect(rendered).to have_selector('div#qle-details-for-existing-sep')
  end

  it "should not display 'existing SEP - Eligible to enroll' partial if there is no active admin SEP" do
    assign(:active_sep, [])
    render file: "insured/families/home.html.erb"
    expect(rendered).to_not have_selector('div#qle-details-for-existing-sep')
  end

  context "Entire Enrollment History for Family" do
    before do
      assign(:hbx_enrollments, [hbx])
      assign(:all_qle_events, [qle_first_of_month])
      assign(:family, family)
    end

     it "should display select box to show all enrollments for HBX admin" do
      assign(:person, person_hbx)
      assign(:all_hbx_enrollments_for_admin, [hbx, term_hbx])
      allow(view).to receive(:current_user).and_return(user_with_hbx_staff_role)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", can_view_entire_family_enrollment_history?: true))
      render file: "insured/families/home.html.erb"
      expect(rendered).to include("Display All Enrollments?")
    end

     it "should NOT display select box to show all enrollments for non HBX admin user" do
      assign(:person, person_employee)
      user_with_employer_role.stub_chain('person.hbx_staff_role.permission').and_return(nil)
      allow(view).to receive(:current_user).and_return(user_with_employer_role)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", can_view_entire_family_enrollment_history?: nil))
      render file: "insured/families/home.html.erb"
      expect(rendered).to_not include("Display All Enrollments?")
    end
  end
end

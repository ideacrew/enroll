require 'rails_helper'

RSpec.describe "insured/families/home.html.erb" do
  let(:person) {FactoryGirl.create(:person, :with_employee_role, :with_family)} #let(:person) { FactoryGirl.create(:person, :with_family ) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_family, :with_hbx_staff_role) }
  let(:user_with_employer_role) {FactoryGirl.create(:user, :with_family, :employer_staff) }
  let(:hbx_staff_permission) { FactoryGirl.create(:permission, :hbx_staff) }

  let!(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month) }
  let(:sep){
    sep = family.special_enrollment_periods.new
    sep.effective_on_kind = 'first_of_month'
    sep.qualifying_life_event_kind= qle_first_of_month
    sep.qualifying_life_event_kind_id = qle_first_of_month.id
    sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
    sep.admin_flag = true
    sep
  }

  # For displaying HBX Enrollment to test subscribe rpolicy actions
  let(:employer_profile) { FactoryGirl.build(:employer_profile) }
  let(:plan) { FactoryGirl.build(:plan) }
  let(:hbx) { HbxEnrollment.new(created_at: TimeKeeper.date_of_record, effective_on: TimeKeeper.date_of_record) }

  before :each do
    stub_template "insured/families/_right_column.html.erb" => ''
    stub_template "insured/families/_qle_detail.html.erb" => ''
    stub_template "insured/families/_enrollment.html.erb" => ''
    stub_template "insured/families/_navigation.html.erb" => ''
    stub_template "insured/families/_shop_for_plans_widget.html.erb" => ''
    stub_template "insured/families/_apply_for_medicaid_widget.html.erb" => ''
    stub_template "insured/plan_shoppings/_help_with_plan.html.erb" => ''
    allow(view).to receive(:current_user).and_return(user_with_employer_role)
    assign(:person, person)

    assign(:family, family)
    render file: "insured/families/home.html.erb"
  end

  it "should display the title" do
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('h1', text: "My #{Settings.site.short_name}")
  end

  it "should have plan-summary area" do
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('div#plan-summary')
  end

  it "should display 'existing SEP - Eligible to enroll' partial if there is an active admin SEP" do
    assign(:active_sep, sep)
    render file: "insured/families/home.html.erb"
    expect(rendered).to have_selector('div#qle-details-for-existing-sep')
  end

  it "should not display 'existing SEP - Eligible to enroll' partial if there is no active admin SEP" do
    assign(:active_sep, [])
    render file: "insured/families/home.html.erb"
    expect(rendered).to_not have_selector('div#qle-details-for-existing-sep')
  end

  context "Subscriber Policy Action Panel" do
    before :each do
      assign(:hbx_enrollments, [hbx])
      assign(:all_qle_events, [qle_first_of_month])
      allow(hbx).to receive(:plan).and_return(plan)
    end

    it "should display for HBX admin with proper action buttons" do
      allow(view).to receive(:current_user).and_return(user_with_hbx_staff_role)
      user_with_hbx_staff_role.stub_chain('person.hbx_staff_role.permission').and_return(hbx_staff_permission)
      render file: "insured/families/home.html.erb"
      expect(rendered).to include("Subscriber Policy Actions")
      actions = ["Add SEP", "Cancel Enrollment", "Create Eligibility", "Reinstate", "Shorten Coverage Span", "Terminate"]
      actions.each { |action| expect(rendered).to include(action) }
    end

    it "should not display for non HBX admin" do
      expect(view.current_user).to eq(user_with_employer_role)
      render file: "insured/families/home.html.erb"
      expect(rendered).not_to include("Subscriber Policy Actions")
    end
  end
end

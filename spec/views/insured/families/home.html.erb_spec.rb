require 'rails_helper'

RSpec.describe "insured/families/home.html.erb" do
  let(:person_employee) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:person) { FactoryBot.create(:person, :with_family) }
  let(:person_hbx) { FactoryBot.create(:person, :with_hbx_staff_role, :with_family) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_family, :with_hbx_staff_role) }
  let(:user_with_employer_role) { FactoryBot.create(:user, :with_family, :employer_staff) }
  let(:hbx_staff_permission) { FactoryBot.create(:permission, :hbx_staff) }
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

  let(:product) { BenefitMarkets::Products::HealthProducts::HealthProduct.create(application_period: TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)}
  let(:hbx) { HbxEnrollment.new(created_at: TimeKeeper.date_of_record, effective_on: TimeKeeper.date_of_record) }
  let(:term_hbx) { HbxEnrollment.new(created_at: TimeKeeper.date_of_record, effective_on: TimeKeeper.date_of_record, aasm_state: "coverage_terminated") }

  before :each do
    stub_template "insured/families/_right_column.html.erb" => ''
    stub_template "insured/families/_qle_detail.html.erb" => ''
    stub_template "insured/families/_navigation.html.erb" => ''
    stub_template "insured/families/_shop_for_plans_widget.html.erb" => ''
    stub_template "insured/families/_apply_for_medicaid_widget.html.erb" => ''
    stub_template "insured/plan_shoppings/_help_with_plan.html.erb" => ''
    stub_template "shared/_pay_now_modal.html.erb" => ''
    assign(:person, person_employee)
    allow(view).to receive(:current_user).and_return(user_with_employer_role)
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", can_view_entire_family_enrollment_history?: true))
    assign(:family, family)
    allow(hbx).to receive(:product).and_return(product)
    allow(term_hbx).to receive(:product).and_return(product)
    allow(view).to receive(:display_carrier_logo).with(any_args).and_return(double)
    allow(view).to receive(:fetch_carrier_key_from_legal_name).with(nil).and_return(double)
  end

  it "should display the title" do
    render template: "insured/families/home.html.erb"
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('h1', text: "My #{EnrollRegistry[:enroll_app].setting(:short_name).item}")
  end

  it "should have plan-summary area" do
    render template: "insured/families/home.html.erb"
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('div#plan-summary')
  end

  it "should display 'existing SEP - Eligible to enroll' partial if there is an active admin SEP" do
    render template: "insured/families/home.html.erb"
    assign(:active_sep, sep)
    render template: "insured/families/home.html.erb"
    expect(rendered).to have_selector('div#qle-details-for-existing-sep')
  end

  it "should not display 'existing SEP - Eligible to enroll' partial if there is no active admin SEP" do
    assign(:active_sep, [])
    render template: "insured/families/home.html.erb"
    expect(rendered).to_not have_selector('div#qle-details-for-existing-sep')
  end

  context "Eligible to Enroll partial" do

    it "does display 'existing SEP - Eligible to enroll' partial if the qualifying life event kind is inactive" do
      sep.qualifying_life_event_kind.update_attributes!(is_active: false)
      render template: "insured/families/home.html.erb"
      assign(:active_sep, sep)
      render template: "insured/families/home.html.erb"
      expect(rendered).to have_selector('div#qle-details-for-existing-sep')
    end
  end

  context "SEP banner display with active SEP and QLE" do

    it "displays 'sep message' partial if the SEP and QLE are active" do
      assign(:active_sep, sep)
      render template: "insured/families/home.html.erb"
      expect(rendered).to have_selector('div#sep_message')
    end
  end

  context "SEP banner display with inactive SEP or QLE" do

    it "displays 'sep message' partial if there is no active qle kind" do
      sep.qualifying_life_event_kind.update_attributes!(is_active: false)
      assign(:active_sep, sep)
      render template: "insured/families/home.html.erb"
      expect(rendered).to have_selector('div#sep_message')
    end

    it "does not display 'sep message' partial if there is no active SEP" do
      allow(family).to receive(:active_seps).and_return(false)
      render template: "insured/families/home.html.erb"
      expect(rendered).to_not have_selector('div#sep_message')
    end
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
      allow(view).to receive(:policy_helper).and_return(
        double("FamilyPolicy", can_view_entire_family_enrollment_history?: true)
      )
      render template: "insured/families/home.html.erb"
      expect(rendered).to include("Display All Enrollments?")
    end

    it "should NOT display select box to show all enrollments for non HBX admin user" do
      assign(:person, person_employee)
      allow(view).to receive(:policy_helper).and_return(
        double("FamilyPolicy", can_view_entire_family_enrollment_history?: nil)
      )
      render template: "insured/families/home.html.erb"
      expect(rendered).to_not include("Display All Enrollments?")
    end
  end

  context ":enrollment_plan_tile_update feature" do
    context 'enabled' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(any_args).and_call_original
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:enrollment_plan_tile_update).and_return(true)
        assign(:person, person_hbx)
        assign(:hbx_enrollments, [hbx])
        allow(view).to receive(:policy_helper).and_return(
          double("FamilyPolicy", can_view_entire_family_enrollment_history?: nil)
        )
      end

      it "should render the refactored plan tile" do
        render
        expect(rendered).to have_selector(".hbx-enrollment-refactored-panel")
      end
    end
  end
end

require 'rails_helper'
require 'pry'

RSpec.describe "insured/families/_shop_for_plans_widget.html.erb" do
  let(:person) { FactoryGirl.build(:person) }
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member) }
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:census_employee) { FactoryGirl.build(:census_employee) }
  let(:hbx_enrollments) {double}
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let(:current_user) { FactoryGirl.create(:user)}


  context "with hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, hbx_enrollments
      assign :family, family
      sign_in(current_user)
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(current_user).to receive(:has_employee_role?).and_return(true)
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      #allow(view).to receive(:has_active_sep?).and_return(false)
      render "insured/families/shop_for_plans_widget"
    end

    it 'should have title' do
      expect(rendered).to have_selector('strong', "Browse Health and Dental plans from carriers in the DC Health Exchange")
    end

    it "should have image" do
      expect(rendered).to have_selector("img")
      expect(rendered).to match /shop_for_plan/
    end

    it "should have form with action" do
      expect(rendered).to have_selector("form[action='/insured/group_selections/new']")
    end

    it "should have form with hidden parameters" do
      expect(rendered).to have_css("input#change_plan[value='change_plan']", :visible => false)
      expect(rendered).to have_css("input#employee_role_id[value='#{employee_role.id}']", :visible => false)
      expect(rendered).to have_css("input#person_id[value='#{person.id}']", :visible => false)
      expect(rendered).to have_css("input#shop_for_plans[value='shop_for_plans']", :visible => false)
    end

  end

  context "action path" do
    let(:benefit_group) { double }
    let(:new_hire_enrollment_period) { TimeKeeper.date_of_record..(TimeKeeper.date_of_record + 30.days) }

    before :each do
      assign :person, person
      assign :family, family
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      allow(view).to receive(:is_under_open_enrollment?).and_return(true)
      sign_in(current_user)
    end

    it "should action to new insured group selection path" do
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_selector("form[action='/insured/group_selections/new']")
    end

    it "should action to find sep insured families path" do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(false)
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
      allow(view).to receive(:is_under_open_enrollment?).and_return(false)
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_selector("form[action='/insured/families/find_sep']")
    end
  end

end

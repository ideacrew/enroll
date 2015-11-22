require 'rails_helper'

RSpec.describe "insured/families/_shop_for_plans_widget.html.erb" do
  let(:person) { FactoryGirl.build(:person) }
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:hbx_enrollments) {double}
  let!(:benefit_coverage_period) { FactoryGirl.create(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record - 10.days, open_enrollment_end_on: TimeKeeper.date_of_record + 10.days) }
  let(:user) { FactoryGirl.create(:user)}


  context "with hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, hbx_enrollments
      render "insured/families/shop_for_plans_widget"
      sign_in user
    end

    it 'should have title' do
      expect(rendered).to have_selector('strong', "Browse Health and Dental plans from carriers in the DC Health Exchange")
    end

    it "should have image" do
      expect(rendered).to have_selector("img")
      expect(rendered).to match /shop_for_plan/
    end

    it "should have link with change_plan" do
      expect(rendered).to have_selector('button', text: 'Shop for Plans')
      expect(rendered).to have_selector('strong', text: 'Shop for health and dental plans')
      expect(rendered).to have_selector("a[href='/insured/group_selections/new?change_plan=change_plan&employee_role_id=#{employee_role.id}&person_id=#{person.id}&shop_for_plan=shop_for_plan']")
    end
  end

  context "without hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
      render "insured/families/shop_for_plans_widget"
    end

    it "should have link without change_plan" do
      expect(rendered).to have_selector("a[href='/insured/group_selections/new?employee_role_id=#{employee_role.id}&person_id=#{person.id}&shop_for_plan=shop_for_plan']")
    end
  end

  context "action path" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
    end

    it "should action to new insured group selection path" do
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(view).to receive(:is_under_open_enrollment?).and_return(true)
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_selector("a[href='/insured/group_selections/new?employee_role_id=#{employee_role.id}&person_id=#{person.id}&shop_for_plan=shop_for_plan']")
    end

    it "should action to find sep insured families path" do
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
      allow(view).to receive(:is_under_open_enrollment?).and_return(false)
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_selector("a[href='/insured/families/find_sep?employee_role_id=#{employee_role.id}&person_id=#{person.id}&shop_for_plan=shop_for_plan']")
    end
  end
end

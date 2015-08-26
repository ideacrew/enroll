require 'rails_helper'

RSpec.describe "insured/families/_shop_for_plans_widget.html.erb" do
  let(:person) { double(id: '123') }
  let(:employee_role) { double(id: '123') }
  let(:hbx_enrollments) {double}

  context "with hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, hbx_enrollments
      render "insured/families/shop_for_plans_widget"
    end

    it 'should have title' do
      expect(rendered).to have_selector('strong', "Browse Health and Dental plans from carriers in the DC Health Exchange")
    end

    it "should have image" do
      expect(rendered).to have_selector("img")
      expect(rendered).to match /shop_for_plan/
    end

    it "should have link with change_plan" do
      expect(rendered).to have_selector("a[href='/group_selection/new?change_plan=change_plan&employee_role_id=#{employee_role.id}&person_id=#{person.id}']", text: 'Shop for Plans')
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
      expect(rendered).to have_selector("a[href='/group_selection/new?employee_role_id=#{employee_role.id}&person_id=#{person.id}']", text: 'Shop for Plans')
    end
  end
end

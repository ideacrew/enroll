require 'rails_helper'

describe "employers/census_employees/new.html.erb" do
  let(:user) { FactoryGirl.create(:user) }
  let(:census_employee) { CensusEmployee.new }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  before :each do
    sign_in user
    assign(:employer_profile, employer_profile)
    assign(:census_employee, census_employee)
    render "employers/census_employees/new"
  end

  context 'for cobra' do
    it 'should have cobra area' do
      expect(rendered).to  have_selector('div#cobra_info')
    end

    it "should have cobra checkbox" do
      expect(rendered).to match /Check the box if this person is already in enrolled into COBRA\/Continuation outside of DC Health Link/
      expect(rendered).to have_selector('input#census_employee_existing_cobra')
    end

    it "should have cobra_begin_date_field" do
      expect(rendered).to have_selector('div#cobra_begin_date_field')
      expect(rendered).to match /COBRA Begin Date/
      expect(rendered).to have_selector('.interaction-field-control-census-employee-cobra_begin_date')
    end
  end
end

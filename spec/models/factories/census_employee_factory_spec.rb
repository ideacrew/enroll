require 'rails_helper'

RSpec.describe Factories::CensusEmployeeFactory, type: :model, dbclean: :after_each do

  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year}
  let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") } 
  let!(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: TimeKeeper.date_of_record, employer_profile: employer_profile) }
  let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }  
  let!(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
 
  context "When Census Employe don't have benefit group assignment" do 
    it 'should set default benefit group assignment with given plan year' do
      expect(census_employee.active_benefit_group_assignment.benefit_group).to eq active_benefit_group
      census_employee_factory = Factories::CensusEmployeeFactory.new
      census_employee_factory.plan_year = renewal_plan_year
      census_employee_factory.census_employee = census_employee
      census_employee_factory.begin_coverage
      expect(census_employee.active_benefit_group_assignment.benefit_group).to eq renewal_benefit_group
    end
  end
end
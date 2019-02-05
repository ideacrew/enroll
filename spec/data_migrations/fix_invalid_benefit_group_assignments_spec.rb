require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_invalid_benefit_group_assignments")

describe FixInvalidBenefitGroupAssignments do
  
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:date_of_record_to_use) { Date.new(calender_year, 5, 10) }

  before(:each) do
    DatabaseCleaner.clean
  end

  before do 
    TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  let(:given_task_name) { "fix_invalid_benefit_group_assignments" }
  subject { FixInvalidBenefitGroupAssignments.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Given valid employer exists with active employees" do

    let(:organization)          { create :organization, legal_name: "Corp 1" }
    let(:employer_profile)      { create :employer_profile, organization: organization }
    let(:effective_on)          { Date.new(calender_year, 5, 1) }
    let(:open_enrollment_start) { Date.new(calender_year, 4, 1) }
    let(:open_enrollment_end)   { Date.new(calender_year, 4, 10) }

    let(:active_plan_year) {
      create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => effective_on.prev_year, :end_on => effective_on.prev_day,
        :open_enrollment_start_on => open_enrollment_start.prev_year, :open_enrollment_end_on => open_enrollment_end.prev_year, fte_count: 5 
    }

    let!(:benefit_group) { create :benefit_group, :with_valid_dental, plan_year: active_plan_year}

    let(:renewing_plan_year) {
      create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolled, :start_on => effective_on, :end_on => effective_on.next_year.prev_day,
        :open_enrollment_start_on => open_enrollment_start, :open_enrollment_end_on => open_enrollment_end, fte_count: 5
    }

    let!(:renewing_benefit_group) { create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year }

    let!(:owner) { create :census_employee, :owner, employer_profile: employer_profile }
    let!(:non_owner_employees) { 
      2.times{|i| create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days } 
      employer_profile.census_employees.non_business_owner
    }

    let!(:census_employees)     { employer_profile.census_employees }

    let!(:employee_enrollments) {
      census_employees.each do |ce|
        person = create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family = Family.find_or_build_from_employee_role(employee_role)

        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.active_benefit_group_assignment,
          benefit_group: benefit_group,
          )
        enrollment.update_attributes(:aasm_state => 'coverage_selected')

        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group,
          )
        enrollment.update_attributes(:aasm_state => 'auto_renewing')
      end
    }

    context "when employees have invalid end dates on benefit group assignments", dbclean: :after_each do

      before(:each) do
        census_employees.each do |census_employee|
          assignment = census_employee.active_benefit_group_assignment
          assignment.end_on = assignment.start_on - 1.day
          assignment.save(:validate => false)
        end
      end
      
      it "should fix date errors on benefit group assignments" do
        census_employees.each do |census_employee|
          expect(census_employee.valid?).to be_falsey
          active_assignment = census_employee.active_benefit_group_assignment
          expect(active_assignment.valid?).to be_falsey
          expect(active_assignment.errors[:end_on]).to include("can't occur before start date")
        end

        subject.migrate

        census_employees.each do |census_employee|
          expect(census_employee.valid?).to be_truthy
        end
      end
    end

    context "when employees active benefit group assignment pointing to old plan year" do 
      before do 
        renewing_plan_year.update(aasm_state: :active)
        active_plan_year.update(aasm_state: :expired)
      end

      it "should fix active benefit group assignment" do
        census_employees.each do |census_employee|
          expect(census_employee.active_benefit_group_assignment.benefit_group).to eq benefit_group
        end

        subject.migrate

        census_employees.each do |census_employee|
          expect(census_employee.active_benefit_group_assignment.benefit_group).to eq renewing_benefit_group
        end    
      end
    end
  end
end
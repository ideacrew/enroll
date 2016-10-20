require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "cancel_dental_offerings_from_renewing_plan_year")

describe CancelDentalOfferingsFromRenewingPlanYear do

  let(:given_task_name) { "cancel_dental_offerings_from_renewing_plan_year" }
  subject { CancelDentalOfferingsFromRenewingPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do
    let(:calender_year) { TimeKeeper.date_of_record.year }
    let(:organization) { FactoryGirl.create(:organization)}
    let(:employer_profile) { FactoryGirl.create :employer_profile, organization: organization}
    let(:active_plan_year) { FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year - 1, 4, 1), :open_enrollment_end_on => Date.new(calender_year - 1, 4, 10), fte_count: 5 }
    let(:renewing_plan_year) { FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolled, :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 10), fte_count: 5 }
    let(:active_benefit_group) { FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: active_plan_year }
    let(:renewing_benefit_group) { FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year}
    let(:census_employee) {
      ce = FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family = Family.find_or_build_from_employee_role(employee_role)
        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group
          )
        enrollment.update_attributes(:aasm_state => 'auto_renewing', coverage_kind: "health")

        enrollment = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group
          )
        enrollment.update_attributes(:aasm_state => 'coverage_selected', coverage_kind: "dental")
        ce
      }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("benefit_group_id").and_return(renewing_benefit_group.id)
      allow(renewing_plan_year).to receive(:hbx_enrollments).and_return census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.where(benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment)
      allow(active_plan_year).to receive(:hbx_enrollments).and_return census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.where(benefit_group_assignment_id: census_employee.active_benefit_group_assignment)
    end

    it "should cancel the dental enrollment" do
      enrollment = renewing_plan_year.hbx_enrollments.where(coverage_kind: "dental").first
      expect(enrollment.aasm_state).to eq "coverage_selected"
      subject.migrate
      id = enrollment.id
      enrollment = HbxEnrollment.find(id)
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should not cancel the health enrollment" do
      enrollment = renewing_plan_year.hbx_enrollments.where(coverage_kind: "health").first
      expect(enrollment.aasm_state).to eq "auto_renewing"
      subject.migrate
      id = enrollment.id
      enrollment = HbxEnrollment.find(id)
      expect(enrollment.aasm_state).to eq "auto_renewing"
    end

    it "should cancel the dental offerings of the selected benefit group" do
      expect(renewing_benefit_group.dental_reference_plan_id).not_to eq nil
      subject.migrate
      id = renewing_benefit_group.id
      renewing_benefit_group = BenefitGroup.find(id)
      expect(renewing_benefit_group.dental_reference_plan_id).to eq nil
    end

    it "should not cancel the dental offerings of the active benefit group" do
      expect(active_benefit_group.dental_reference_plan_id).not_to eq nil
      subject.migrate
      id = active_benefit_group.id
      active_benefit_group = BenefitGroup.find(id)
      expect(active_benefit_group.dental_reference_plan_id).not_to eq nil
    end
  end
end

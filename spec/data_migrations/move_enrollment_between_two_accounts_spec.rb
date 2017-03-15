require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_enrollment_between_two_accounts")

describe MoveEnrollmentBetweenTwoAccount do

  let(:given_task_name) { "move_enrollment_between_two_accounts" }
  subject { MoveEnrollmentBetweenTwoAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "it should move an ivl enrollment" do
    let(:family1) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:family2) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) {
       FactoryGirl.create(:hbx_enrollment,
                           household: family1.active_household,
                           coverage_kind: "health",
                           kind: "individual",
                           submitted_at: TimeKeeper.date_of_record,
                           consumer_role: consumer_role,
                           aasm_state: 'shopping')
                        }
    let(:consumer_role) {FactoryGirl.create(:consumer_role,person: family1.family_members[0].person)}
    let!(:hbx_profile) {FactoryGirl.create(:hbx_profile,:open_enrollment_coverage_period)}
    before do
      coverage_household_member = family1.households.first.coverage_households.first.coverage_household_members.first
      h = HbxEnrollmentMember.new_from(coverage_household_member: coverage_household_member)
      h.eligibility_date = TimeKeeper.date_of_record-2
      h.coverage_start_on = TimeKeeper.date_of_record-2
      hbx_enrollment.hbx_enrollment_members << h
      hbx_enrollment.save

      allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return family1.family_members[0].person.hbx_id
      allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return family2.family_members[0].person.hbx_id
    end
    it "should move an ivl enrollment" do
      expect(family1.active_household.hbx_enrollments).to include(hbx_enrollment)
      expect(family2.active_household.hbx_enrollments).not_to include(hbx_enrollment)
      @size=family2.active_household.hbx_enrollments.size
      subject.migrate
      family1.reload
      family2.reload
      expect(family1.active_household.hbx_enrollments).not_to include(hbx_enrollment)
      expect(family2.active_household.hbx_enrollments.last.kind).to eq hbx_enrollment.kind
      expect(family2.active_household.hbx_enrollments.last.consumer_role).to eq hbx_enrollment.consumer_role
      expect(family2.active_household.hbx_enrollments.size).to eq @size+1
    end
  end
  describe "it should move a shop enrollment" do
    let(:family1) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:family2) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment,
                         household: family1.active_household,
                         coverage_kind: "health",
                         kind: "employer_sponsored",
                         submitted_at: TimeKeeper.date_of_record,
                         employee_role: employee_role,
                         aasm_state: 'shopping',
                         benefit_group_assignment: benefit_group_assignment)
    }
    let(:employee_role) {FactoryGirl.create(:employee_role,person: family1.family_members[0].person, census_employee:census_employee, employer_profile: benefit_group_assignment.benefit_group.plan_year.employer_profile)}
    let!(:employee_role2) {FactoryGirl.create(:employee_role,person: family2.family_members[0].person, census_employee:census_employee, employer_profile: benefit_group_assignment.benefit_group.plan_year.employer_profile)}
    let(:census_employee){FactoryGirl.create(:census_employee)}
    let(:benefit_group_assignment) {FactoryGirl.create(:benefit_group_assignment,census_employee:census_employee)}
    before do
      coverage_household_member = family1.households.first.coverage_households.first.coverage_household_members.first
      h = HbxEnrollmentMember.new_from(coverage_household_member: coverage_household_member)
      h.eligibility_date = TimeKeeper.date_of_record
      h.coverage_start_on = TimeKeeper.date_of_record
      hbx_enrollment.hbx_enrollment_members << h
      hbx_enrollment.save
      benefit_group_assignment.benefit_group.plan_year.update_attribute(:aasm_state, "published")

      allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return family1.family_members[0].person.hbx_id
      allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return family2.family_members[0].person.hbx_id
    end
    it "should move an ivl enrollment" do
      expect(family1.active_household.hbx_enrollments).to include(hbx_enrollment)
      expect(family2.active_household.hbx_enrollments).not_to include(hbx_enrollment)
      @size=family2.active_household.hbx_enrollments.size
      subject.migrate
      family1.reload
      family2.reload
      expect(family1.active_household.hbx_enrollments).not_to include(hbx_enrollment)
      expect(family2.active_household.hbx_enrollments.last.kind).to eq hbx_enrollment.kind
      expect(family2.active_household.hbx_enrollments.last.employee_role).to eq hbx_enrollment.employee_role
      expect(family2.active_household.hbx_enrollments.size).to eq @size+1
    end
  end
 end
require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_due_date_affected_by_FEL_notice")

describe CorrectDueDateAffectedByFELNotice do

  let(:given_task_name) { "correct_due_date_affected_by_FEL_notice" }
  subject { CorrectDueDateAffectedByFELNotice.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change due date" do
    let!(:person)             { FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let!(:aasm_state)             {person.consumer_role.update_attributes(aasm_state: "verification_outstanding")}
    let!(:family)             { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:ivl_enrollment)          { FactoryGirl.build(:hbx_enrollment, household: family.active_household,
                                  kind: "individual", aasm_state: "coverage_selected", is_any_enrollment_member_outstanding: true) }
    let!(:ivl_enrollment_member)  { FactoryGirl.create(:hbx_enrollment_member, is_subscriber: true,
                                  applicant_id: family.primary_applicant.id, hbx_enrollment: ivl_enrollment,
                                  eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record) }

    it "should not change due date if family does not have min_verification_due_date" do
      expect(person.families.first.min_verification_due_date).to eq(nil)
      subject.migrate
      person.reload
      expect(person.families.first.min_verification_due_date).to eq(nil)
    end

    it "should not change due date if primary applicant does not receive notices" do
      subject.migrate
      person.reload
      expect(person.families.first.min_verification_due_date).to eq(nil)
    end

    it "should not change due date if primary applicant does not receive FEL notices before certain date " do
      person.inbox.messages.first.update_attributes(subject:"Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance", created_at:Date.new(2018,10,18))
      person.families.first.update_attributes(min_verification_due_date: Date.new(2019,2,10))
      subject.migrate
      person.reload     
      expect(person.families.first.min_verification_due_date).to eq(Date.new(2019,2,10))
    end

    it "should not change due date if primary applicant receives FEL  notices after certain date" do
      person.consumer_role.verification_types.each do |type|
        type.update_attributes(validation_status: "outstanding")
      end
      family = Family.where(min_verification_due_date: Date.new(2019,2,10))
      person.inbox.messages.first.update_attributes!(subject:"Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance",created_at:Date.new(2018,11,18))
      person.families.first.update_attributes!(min_verification_due_date: Date.new(2019,2,10))
      subject.migrate
      person.reload
      person.families.first.reload
      expect(person.families.first.min_verification_due_date).to eq(Date.new(2019,3,21))
    end
  end
end

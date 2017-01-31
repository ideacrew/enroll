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

  describe "adding coverage household member", dbclean: :after_each do

    let(:person1) { FactoryGirl.create(:person, hbx_id: "0000") }
    let(:person2) { FactoryGirl.create(:person, hbx_id: "1111") }
    #let(:family_member2) {FactoryGirl.create(:family_member)}
    let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, person: person1)}
    let(:hbx_enrollment_member) {person2}
    let(:family2) { FactoryGirl.create(:family, :with_primary_family_member, person: person2)}

    let(:hbx_enrollment1) {FactoryGirl.create(:hbx_enrollment,hbx_id:"2222",household: family1.active_household)}
    let(:hbx_enrollment2) {FactoryGirl.create(:hbx_enrollment,hbx_id:"3333",household: family1.active_household)}
    let(:hbx_enrollment3) {FactoryGirl.create(:hbx_enrollment,hbx_id:"4444",household: family2.active_household)}




    before do
      allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return person1.hbx_id
      allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return person2.hbx_id
      allow(ENV).to receive(:[]).with('enrollment_hbx_id').and_return hbx_enrollment1.hbx_id
    end

    it "should remove the enrollment from person1 to person2" do
      person1.save
      person2.save
      family1.save
      family2.save
      expect(person1.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment1)
      expect(person2.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment1)
      subject.migrate
      family1.reload
      family2.reload
      expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment1)
      expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment1)

    end

  end
end
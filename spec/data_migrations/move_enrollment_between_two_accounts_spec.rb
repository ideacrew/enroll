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


  describe "move an enrollment from one person to another person", dbclean: :after_each do
    subject { MoveEnrollmentBetweenTwoAccount.new(given_task_name, double(:current_scope => nil)) }
    before do
      allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return person2.hbx_id
      allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return person1.hbx_id
      allow(ENV).to receive(:[]).with('enrollment_hbx_id').and_return hbx_enrollment.hbx_id
    end
    context "hbx_enrollment is movable" do
      let(:person1) { FactoryGirl.create(:person, hbx_id: "0000") }
      let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, person: person1)}
      let(:person2) { FactoryGirl.create(:person, hbx_id: "1111") }
      let(:family2) { FactoryGirl.create(:family, :with_primary_family_member, person: person2)}
      let(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family2.active_household)}
      let(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,applicant_id:person2.id,eligibility_date:Date.new(),hbx_enrollment: hbx_enrollment)
      }
      before do
        family1.add_family_member(person2)
        family1.relate_new_member(person2, "child")
        person2.save
        family2.save
      end
      it "should be movable" do
        expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment)
        expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        subject.migrate
        family1.reload
        family2.reload
        expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment)
      end
    end

    context "hbx_enrollment is not movable" do
      let(:person1) { FactoryGirl.create(:person, hbx_id: "0000") }
      let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, person: person1)}
      let(:person2) { FactoryGirl.create(:person, hbx_id: "1111") }
      let(:family2) { FactoryGirl.create(:family, :with_primary_family_member, person: person2)}
      let(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family2.active_household)}
      let(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,applicant_id:person2.id,eligibility_date:Date.new(),hbx_enrollment: hbx_enrollment)
      }
      before do
        person2.save
        family2.save
        person1.save
        family1.save
      end
      it "should not be movable" do
        expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment)
        expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        subject.migrate
        family1.reload
        family2.reload
        expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment)
      end
    end
  end


  describe ".moveable", dbclean: :after_each do
    let(:person1) { FactoryGirl.create(:person, hbx_id: "0000") }
    let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, person: person1)}
    let(:person2) { FactoryGirl.create(:person, hbx_id: "1111") }
    let(:family2) { FactoryGirl.create(:family, :with_primary_family_member, person: person2)}
    let(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family2.active_household)}
    context "the enrollment has no enrollment member" do
      it "should be movable" do
        expect(subject.moveable(family1,hbx_enrollment)).to eql true
      end
    end
    context "the enrollment has enrollment members but not are subset of family members" do
      let(:hbx_enrollment_member){FactoryGirl.create(:hbx_enrollment_member,applicant_id:person2.id,eligibility_date:Date.new(),hbx_enrollment: hbx_enrollment)
      }
      before do
        family1.add_family_member(person2)
        family1.relate_new_member(person2, "child")
      end
      it "should be movable" do
        expect(subject.moveable(family1,hbx_enrollment)).to eql true
      end
    end
    context "the enrollment has members that are not a subset of family's  members" do
      let!(:hbx_enrollment_member){ FactoryGirl.create(:hbx_enrollment_member, applicant_id:family2.primary_family_member.id,
                                                        eligibility_date:Date.new(), hbx_enrollment: hbx_enrollment)
                                  }
      it "should not be movable" do
        expect(subject.moveable(family1,hbx_enrollment)).to eql false
      end
    end
  end

end
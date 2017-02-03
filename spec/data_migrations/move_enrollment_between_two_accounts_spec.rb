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


  # #example:
  # describe "Delete dental enrollments" do
  #   subject { DeleteDentalEnrollment.new }
  #
  #   context "a family with 2 dental and 2 health enrollments" do
  #     let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
  #     let(:dental_enrollment1) {FactoryGirl.create(:hbx_enrollment, :with_dental_coverage_kind, household: family.active_household)}
  #     let(:dental_enrollment2) {FactoryGirl.create(:hbx_enrollment, :with_dental_coverage_kind, household: family.active_household)}
  #     let(:health_enrollment1) {FactoryGirl.create(:hbx_enrollment,household: family.active_household)}
  #     let(:health_enrollment2) {FactoryGirl.create(:hbx_enrollment,household: family.active_household)}
  #
  #     it "deletes the dentals" do
  #       expect(family.active_household.hbx_enrollments).to include dental_enrollment1
  #       expect(family.active_household.hbx_enrollments).to include dental_enrollment2
  #       expect(family.active_household.hbx_enrollments).to include health_enrollment1
  #       expect(family.active_household.hbx_enrollments).to include health_enrollment2
  #       family.primary_applicant.person.update_attribute(:hbx_id, "1234567890")
  #       expect(family.primary_applicant.person.hbx_id).to eq "1234567890"
  #       DeleteDentalEnrollment.migrate("1234567890")
  #       p = Person.where(hbx_id: "1234567890").first
  #       expect(p.primary_family.active_household.hbx_enrollments.where(coverage_kind: "health").size).to eq 2
  #       expect(p.primary_family.active_household.hbx_enrollments.where(coverage_kind: "dental").size).to eq 0
  #     end
  #   end
  # end



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
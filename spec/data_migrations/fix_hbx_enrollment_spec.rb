require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_hbx_enrollments")

#1. Move enrollment to contingent state if any of hbx_enrollment_members has outstanding status

describe FixHbxEnrollments, dbclean: :after_each do
  subject { FixHbxEnrollments.new("fix_hbx_enrollments", double(:current_scope => nil)) }
  verification_states = %w(unverified ssa_pending dhs_pending verification_outstanding fully_verified verification_period_ended)
  verification_states.each do |state|
    obj=(state+"_person").to_sym
    let(obj) {
      person = FactoryGirl.create(:person, :with_consumer_role)
      person.consumer_role.aasm_state = state
      person
    }

    family_member = (state+"_family_member").to_sym
    let(family_member) { FamilyMember.new(person: eval(obj.to_s)) }
    hbx_enrollment_member = (state+"_enrollment_member").to_sym
    let(hbx_enrollment_member) { FactoryGirl.build(:hbx_enrollment_member, applicant_id: eval(family_member.to_s) ) }
  end

  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:enrollment) {
    FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: TimeKeeper.date_of_record,
                       aasm_state: 'shopping')
  }

  context "assigns proper states for people" do
    verification_states.each do |status|
      it "#{status}_person has #{status} aasm_state" do
        expect(eval("#{status}_person").consumer_role.aasm_state).to eq status
      end
    end
  end

  describe "verification incomplete" do
    before :each do
      allow(subject).to receive(:get_families).and_return([family])
      allow(subject).to receive(:get_enrollments).and_return([enrollment])
    end
    context "enrollment with outstanding member" do
      it "moves hbx_enrollment to enrolled_contingent state" do
        allow(subject).to receive(:get_members).and_return([verification_outstanding_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "enrolled_contingent"
      end
    end

    context "enrollment with verification_period_ended member" do
      it "moves hbx_enrollment to enrolled_contingent state" do
        allow(subject).to receive(:get_members).and_return([verification_period_ended_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "enrolled_contingent"
      end
    end

    context "enrollment with outstanding members" do
      it "moves hbx_enrollment to enrolled_contingent state" do
        allow(subject).to receive(:get_members).and_return([verification_outstanding_person.consumer_role, fully_verified_person.consumer_role, ssa_pending_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "enrolled_contingent"
      end
    end
  end
end
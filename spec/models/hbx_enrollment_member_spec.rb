require 'rails_helper'

describe HbxEnrollmentMember, dbclean: :around_each do

  context "an hbx_enrollment with members exists", dbclean: :around_each do
    include_context "BradyWorkAfterAll"

    attr_reader :household, :coverage_household, :enrollment, :family_member_ids

    before :all do
      TimeKeeper.set_date_of_record_unprotected!(Time.zone.today)
      create_brady_census_families
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      @enrollment = household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group,
        benefit_group_assignment: @mikes_benefit_group_assignments
      )
      @family_member_ids = mikes_family.family_members.collect(&:_id)
    end

    context "the first hbx enrollment member" do
      let!(:enrollment_member) {enrollment.hbx_enrollment_members.first}

      it "should have a family member" do
        expect(family_member_ids).to include(enrollment_member.family_member._id)
      end

      it "should know its relationship to the subscriber" do
        expect(enrollment_member.primary_relationship).to eq enrollment_member.family_member.primary_relationship
      end
    end

    context "validate hbx_enrollment_member" do
      let!(:subscriber) {enrollment.hbx_enrollment_members.first}
      let!(:enrollment_members) {enrollment.hbx_enrollment_members}

      it "should not raise error if subscriber(primary applicant) is selected during enrollment" do
        expect(@enrollment.valid?).to be_truthy
        expect(@enrollment.hbx_enrollment_members.first.errors[:is_subscriber].any?).to be_falsey
      end

      # it "should raise if subscriber(primary applicant) is not selected during enrollment" do
      #   enrollment_members.reject!{ |a| a._id == subscriber._id }
      #   expect(@enrollment.valid?).to be_falsey
      #   expect(@enrollment.hbx_enrollment_members.first.errors[:is_subscriber].any?).to be_truthy
      # end

      context "should not raise error if employee_role is blank" do
        it "when subscriber is selected during enrollment" do
          allow(@enrollment).to receive(:employee_role).and_return(nil)
          expect(@enrollment.valid?).to be_truthy
          expect(@enrollment.hbx_enrollment_members.first.errors[:is_subscriber].any?).to be_falsey
        end

        it "when subscriber is not selected during enrollment" do
          enrollment_members.reject!{ |a| a._id == subscriber._id }
          allow(@enrollment).to receive(:employee_role).and_return(nil)
          expect(@enrollment.valid?).to be_truthy
          expect(@enrollment.hbx_enrollment_members.first.errors[:is_subscriber].any?).to be_falsey
        end
      end

      context "validate hbx_enrollment_members" do
        
        it "should not raise error if subscriber(primary applicant) is selected during enrollment" do
          expect(@enrollment.valid?).to be_truthy
          expect(@enrollment.hbx_enrollment_members.first.errors[:hbx_enrollment_members].any?).to be_falsey
        end
      end
    end
  end

  context "given a family member", dbclean: :around_each do
    let(:person) { double(full_name: 'John Smith10') }
    let(:family_member) { instance_double(FamilyMember, :person => person ) }
    subject { HbxEnrollmentMember.new }

    before :each do
      allow(subject).to receive(:family_member).and_return(family_member)
    end

    it "delegates #person to the family member" do
      expect(subject.person).to eq person
    end

    it "delegates #ivl_coverage_selected to the family member" do
      expect(family_member).to receive(:ivl_coverage_selected)
      subject.ivl_coverage_selected
    end

    it "should return person's full_name" do
      expect(subject.full_name).to eq person.full_name
    end
  end

  context 'osse_eligible_on_effective_date?' do

    let(:consumer_role) { create(:consumer_role, person: person) }
    let(:person) { enrollment_member.person }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:enrollment) { create(:hbx_enrollment, family: family, household: family.active_household, effective_on: effective_on)}
    let(:enrollment_member) { create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, hbx_enrollment: enrollment, coverage_start_on: effective_on) }
    let(:effective_on) { TimeKeeper.date_of_record }
    let(:start_on) { TimeKeeper.date_of_record }
    let(:osse_eligible) { true }

    before do
      allow(::EnrollRegistry).to receive(:feature?).and_return(true)
      allow(::EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      allow(enrollment_member).to receive(:ivl_osse_eligibility_is_enabled?).and_return(osse_eligible)
    end

    context 'when consumer is osse eligible' do
      let(:ee_elig) { build(:eligibility, :with_subject, :with_evidences, start_on: start_on) }
      let!(:eligibility) do
        consumer_role.eligibilities << ee_elig
        consumer_role.save!
        consumer_role.eligibilities.first
      end

      context 'when osse is enabled for the given year' do
        it { expect(enrollment_member.osse_eligible_on_effective_date?).to be_truthy }
      end

      context 'when osse is disabled for the given year' do
        let(:osse_eligible) { false }

        it { expect(enrollment_member.osse_eligible_on_effective_date?).to be_falsey }
      end
    end

    context 'when consumer is not osse eligible' do
      context 'when osse is enabled for the given year' do
        it { expect(enrollment_member.osse_eligible_on_effective_date?).to be_falsey }
      end
    end
  end
end

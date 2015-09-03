require "rails_helper"

describe RuleSet::HbxEnrollment::IndividualMarketVerification do
  subject { RuleSet::HbxEnrollment::IndividualMarketVerification.new(enrollment) }
  let(:enrollment) { instance_double(HbxEnrollment, :currently_active? => is_currently_active, :benefit_sponsored? => is_shop_enrollment) }
  let(:is_currently_active) { true }
  let(:is_shop_enrollment) { false }

  describe "for a shop policy" do
    let(:is_shop_enrollment) { true }

    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "for an inactive individual policy" do
    let(:is_currently_active) { false }
    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "for an active individual policy" do
    let(:enrollment_members) { [] }
    before(:each) do
      allow(enrollment).to receive(:hbx_enrollment_members).and_return(enrollment_members)
    end
    it "should not be applicable" do
      expect(subject.applicable?).to eq true
    end


    describe "with 2 members" do
      let(:consumer_role_1) { instance_double(ConsumerRole) }
      let(:person_1) { instance_double(Person, :consumer_role => consumer_role_1) }
      let(:member_1) { 
        instance_double(HbxEnrollmentMember, :person => person_1)
      }
      let(:consumer_role_2) { instance_double(ConsumerRole) }
      let(:person_2) { instance_double(Person, :consumer_role => consumer_role_2) }
      let(:member_2) { 
        instance_double(HbxEnrollmentMember, :person => person_2)
      }
      describe "where one of the members is pending and the other has passed validation" do
        let(:enrollment_members) { [member_1, member_2] }
        before :each do
          allow(consumer_role_1).to receive(:verifications_pending?).and_return(false)
          allow(consumer_role_2).to receive(:verifications_pending?).and_return(true)
        end

        it "should recommend the unverified state" do
          expect(subject.determine_next_state).to eq(:move_to_pending!)
        end
      end
      describe "where one of the members is pending and the other has failed validation" do
        let(:enrollment_members) { [member_1, member_2] }
        before :each do
          allow(consumer_role_1).to receive(:verifications_pending?).and_return(true)
          allow(consumer_role_2).to receive(:verifications_pending?).and_return(false)
        end

        it "should recommend the unverified state" do
          expect(subject.determine_next_state).to eq(:move_to_pending!)
        end
      end
      describe "where one of the members is verified and the other has failed validation" do
        let(:enrollment_members) { [member_1, member_2] }
        before :each do
          allow(consumer_role_1).to receive(:verifications_pending?).and_return(false)
          allow(consumer_role_2).to receive(:verifications_pending?).and_return(false)
          allow(consumer_role_1).to receive(:verifications_outstanding?).and_return(false)
          allow(consumer_role_2).to receive(:verifications_outstanding?).and_return(true)
        end

        it "should recommend the enrolled_contingent state" do
          expect(subject.determine_next_state).to eq(:move_to_contingent!)
        end
      end
    end
  end
end

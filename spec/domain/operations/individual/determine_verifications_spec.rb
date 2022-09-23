# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::Individual::DetermineVerifications, dbclean: :after_each do

  subject do
    described_class.new.call(id: consumer_role_id)
  end

  let(:consumer_role_id) { consumer_role.id }

  context 'when consumer role id is nil' do
    let(:consumer_role_id) { nil }

    it 'returns failure' do
      expect(subject.failure?).to eq true
    end
  end

  context 'when person is nil' do
    let(:consumer_role) { ConsumerRole.new }

    it 'returns failure' do
      expect(subject.failure?).to eq true
    end
  end

  context 'when person is not applying for coverage' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) do
      role = person.consumer_role
      role.update_attributes(is_applying_coverage: false)
      role
    end

    it 'returns failure' do
      expect(subject.failure?).to eq true
    end
  end

  describe 'when person and consumer role exists' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }

    context "when trigger_verifications_before_enrollment_purchase is enabled" do
      before do
        EnrollRegistry[:trigger_verifications_before_enrollment_purchase].feature.stub(:is_enabled).and_return(true)
      end

      it 'returns success' do
        expect(subject.success?).to eq true
        expect(subject.success).to eq "Successfully triggered Hub Calls for ConsumerRole with person_hbx_id: #{person.hbx_id}"
      end

      it 'updates consumer_role state to verification_outstanding' do
        expect(consumer_role.aasm_state).to eq 'unverified'
        subject
        expect(consumer_role.reload.aasm_state).to eq 'verification_outstanding'
      end
    end

    context "when trigger_verifications_before_enrollment_purchase is disabled" do
      before do
        EnrollRegistry[:trigger_verifications_before_enrollment_purchase].feature.stub(:is_enabled).and_return(false)
      end

      context "if person don't have an active enrollment" do
        it 'returns success' do
          expect(subject.success?).to eq false
          expect(subject.failure).to eq "ConsumerRole with person_hbx_id: #{person.hbx_id} is not enrolled to trigger hub calls"
        end

        it 'updates consumer_role state to verification_outstanding' do
          expect(consumer_role.aasm_state).to eq 'unverified'
          subject
          expect(consumer_role.reload.aasm_state).to eq 'unverified'
        end
      end

      context "if person has an active enrollment" do
        let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
        let!(:enrollment) do
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :individual_assisted,
            family: family,
            consumer_role_id: consumer_role.id,
            enrollment_members: family.family_members
          )
        end

        it 'returns success' do
          expect(subject.success?).to eq true
          expect(subject.success).to eq "Successfully triggered Hub Calls for ConsumerRole with person_hbx_id: #{person.hbx_id}"
        end

        it 'updates consumer_role state to verification_outstanding' do
          expect(consumer_role.aasm_state).to eq 'unverified'
          subject
          expect(consumer_role.reload.aasm_state).to eq 'verification_outstanding'
        end
      end
    end
  end
end

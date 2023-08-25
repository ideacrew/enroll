# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::Individual::DetermineVerifications, dbclean: :after_each do

  describe '#call' do
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

  describe 'create type_history_elements for triggered hub_calls' do
    before :each do
      DatabaseCleaner.clean
    end
    context '#valid ssn' do
      let(:consumer_role) { FactoryBot.create(:consumer_role)}
      let(:result) {  described_class.new.call(id: consumer_role.id) }
      before :each do
        EnrollRegistry[:trigger_verifications_before_enrollment_purchase].feature.stub(:is_enabled).and_return(true)
        allow(ConsumerRole).to receive(:find).and_return(consumer_role)
        result
      end

      it 'should record history in ssn_type for requested hub calls' do
        types = consumer_role.verification_types
        ssn_type_histories = types.ssn_type.first.type_history_elements
        ssn_type_histories.map(&:action).should include('Hub Request')
        citizenship_type_histories = types.citizenship_type.first.type_history_elements
        citizenship_type_histories.map(&:action).should include('Hub Request')
      end

      it 'should set verification_type to pending' do
        types = consumer_role.verification_types
        expect(types.ssn_type.first.validation_status).to eq 'pending'
        expect(types.citizenship_type.first.validation_status).to eq 'pending'
      end
    end

    context '#invalid ssn ' do
      before :all do
        DatabaseCleaner.clean
      end

      context 'when validate_and_record_publish_errors feature is enabled' do
        let!(:person) {FactoryBot.create(:person, ssn: '999001234')}
        let!(:consumer_role) do
          consumer = ConsumerRole.new(person: person, is_applicant: true, citizen_status: "us_citizen")
          consumer.ensure_verification_types
          consumer.save!
          consumer
        end
        let(:result) {  Operations::Individual::DetermineVerifications.new.call(id: consumer_role.id) }
        let(:ssa_validator) { instance_double(Operations::Fdsh::Ssa::H3::RequestSsaVerification) }
        let(:vlp_validator) { instance_double(Operations::Fdsh::Vlp::H92::RequestInitialVerification) }

        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:vlp_h92).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:trigger_verifications_before_enrollment_purchase).and_return(true)
          allow(ssa_validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid payload'))
          allow(Operations::Fdsh::Ssa::H3::RequestSsaVerification).to receive(:new).and_return(ssa_validator)
          allow(vlp_validator).to receive(:call).and_return(Dry::Monads::Success())
          allow(Operations::Fdsh::Vlp::H92::RequestInitialVerification).to receive(:new).and_return(vlp_validator)
          allow(ConsumerRole).to receive(:find).and_return(consumer_role)
          result
        end

        it 'should record history in ssn_type for requested hub calls' do
          types = consumer_role.verification_types
          histories = types.ssn_type.first.type_history_elements
          expect(histories.select{|history| ['Hub Request', 'Hub Request Failed'].include?(history.action)}.present?).to be_truthy
        end

        it 'should record history in citizenship_type for requested hub calls' do
          types = consumer_role.verification_types
          histories = types.citizenship_type.first.type_history_elements
          expect(histories.select{|history| ['Hub Request'].include?(history.action)}.present?).to be_truthy
        end
      end

      context 'when validate_and_record_publish_errors feature is disabled' do
        let!(:person) {FactoryBot.create(:person, ssn: '999001234')}
        let!(:consumer_role) do
          consumer = ConsumerRole.new(person: person, is_applicant: true, citizen_status: "us_citizen")
          consumer.ensure_verification_types
          consumer.save!
          consumer
        end
        let(:result) {  Operations::Individual::DetermineVerifications.new.call(id: consumer_role.id) }
        let(:ssa_validator) { instance_double(Operations::Fdsh::Ssa::H3::RequestSsaVerification) }
        let(:vlp_validator) { instance_double(Operations::Fdsh::Vlp::H92::RequestInitialVerification) }

        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:vlp_h92).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:trigger_verifications_before_enrollment_purchase).and_return(true)
          allow(ConsumerRole).to receive(:find).and_return(consumer_role)
          allow(ssa_validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid payload'))
          allow(Operations::Fdsh::Ssa::H3::RequestSsaVerification).to receive(:new).and_return(ssa_validator)
          allow(vlp_validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid payload'))
          allow(Operations::Fdsh::Vlp::H92::RequestInitialVerification).to receive(:new).and_return(vlp_validator)
          result
        end

        it 'should record history in ssn_type for requested hub calls' do
          types = consumer_role.verification_types
          expect(types.ssn_type.first.type_history_elements.count).to eq 1
          expect(types.citizenship_type.first.type_history_elements.count).to eq 1
        end

        it 'should set verification_type to pending' do
          types = consumer_role.verification_types
          expect(types.ssn_type.first.validation_status).to eq 'pending'
          expect(types.citizenship_type.first.validation_status).to eq 'pending'
        end
      end
    end
  end
end

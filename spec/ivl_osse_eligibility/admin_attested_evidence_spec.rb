# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IvlOsseEligibility::AdminAttestedEvidence, type: :model, dbclean: :after_each do
  describe 'A new model instance' do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to have_fields(:title, :key) }
    it do
      is_expected.to have_field(:is_satisfied).of_type(
        Mongoid::Boolean
      ).with_default_value_of(false)
    end
    it { is_expected.to embed_many(:state_histories) }

    context 'with all required fields' do
      subject do
        create(
          :ivl_osse_admin_attested_evidence,
          :with_state_history
        )
      end

      context 'with all required arguments' do
        it 'should be valid' do
          subject.validate
          expect(subject).to be_valid
        end

        it 'should be findable' do
          subject.save!
          expect(described_class.find(subject.id)).to eq subject
        end

        context '.save' do
          before { subject.save! }

          it 'should have state history' do
            record = described_class.find(subject.id)
            expect(record.state_histories).not_to be_empty
          end

          it 'should delegate methods to latest state history' do
            record = described_class.find(subject.id)

            history = record.state_histories.last

            expect(record.effective_on).to eq history.effective_on
            expect(record.is_eligible).to eq history.is_eligible
            expect(record.current_state).to eq history.to_state
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::EdiGateway::InsurancePolicies::RequestRefresh, dbclean: :after_each do

  subject { described_class.new.call(input_params) }

  describe '#call' do
    context 'with valid refresh_period' do
      let(:input_params) { { refresh_period: start_timestamp..end_timestamp } }

      context 'timestamps in UTC' do
        let(:end_timestamp) { (Time.now - 1.hours).utc }
        let(:start_timestamp) { (Time.now - 10.hours).utc }

        it 'returns success with a message' do
          expect(subject.success).to eq('Successfully published event: events.insurance_policies.refresh_requested')
        end
      end

      context 'timestamps not in UTC' do
        let(:end_timestamp) { (Time.now - 1.hours) }
        let(:start_timestamp) { (Time.now - 10.hours) }

        it 'returns success with a message' do
          expect(subject.success).to eq('Successfully published event: events.insurance_policies.refresh_requested')
        end
      end
    end

    context 'with an invalid refresh_period' do
      context 'with no refresh_period key value' do
        let(:input_params) { {} }

        it 'returns failure with a message' do
          expect(subject.failure).to eq('refresh_period must be a range with timestamps and max timestamps must be equal to or less than current time.')
        end
      end

      context 'with bad refresh_period data types' do
        let(:input_params) { { refresh_period: 2..6 } }

        it 'returns failure with a message' do
          expect(subject.failure).to eq('refresh_period must be a range with timestamps and max timestamps must be equal to or less than current time.')
        end
      end

      context 'with bad refresh_period date range' do
        let(:input_params) do
          { refresh_period: TimeKeeper.date_of_record.next_month..TimeKeeper.date_of_record.prev_month }
        end

        it 'returns failure with a message' do
          expect(subject.failure).to eq('refresh_period must be a range with timestamps and max timestamps must be equal to or less than current time.')
        end
      end
    end
  end
end

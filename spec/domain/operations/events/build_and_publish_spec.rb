# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Events::BuildAndPublish, dbclean: :after_each do
  subject { described_class.new.call(input_params) }

  describe '#call' do
    context 'with valid input params' do
      let(:input_params) do
        {
          event_name: 'events.families.found_by',
          attributes: { test: 'test' },
          headers: { correlation_id: 'correlation_id' }
        }
      end

      it 'returns success with a message' do
        expect(subject.success).to eq(
          "Successfully published event: #{input_params[:event_name]}"
        )
      end
    end

    context 'with invalid input params' do
      context 'without key named event_name' do
        let(:input_params) { { attributes: { test: 'test' }, headers: { correlation_id: 'correlation_id' } } }

        it 'returns a failure with a message' do
          expect(
            subject.failure
          ).to include('event_name is required and must be a string')
        end
      end

      context 'without key named attributes' do
        let(:input_params) { { event_name: 'events.families.found_by', headers: { correlation_id: 'correlation_id' } } }

        it 'returns a failure with a message' do
          expect(
            subject.failure
          ).to include('attributes is required and must be a hash')
        end
      end

      context 'without key named headers' do
        let(:input_params) { { event_name: 'events.families.found_by', attributes: { test: 'test' } } }

        it 'returns a failure with a message' do
          expect(
            subject.failure
          ).to include('headers is required')
        end
      end
    end
  end
end

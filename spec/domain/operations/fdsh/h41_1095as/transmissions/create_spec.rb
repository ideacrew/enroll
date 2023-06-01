# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Fdsh::H411095as::Transmissions::Create do
  subject { described_class.new }

  context 'with invalid params' do
    it 'should return errors' do
      result = subject.call({})

      expect(result.failure?).to be_truthy
      expect(result.failure).to include('assistance_year required')
      expect(result.failure).to include('report_types required')
    end

    context 'when invalid report types passed' do
      it 'should return errors' do
        result =
          subject.call(
            { assistance_year: Date.today.year, report_types: %w[original new] }
          )

        expect(result.failure?).to be_truthy
        expect(result.failure).not_to include('assistance_year required')
        expect(result.failure).to include('invalid report_types')
      end
    end
  end

  context 'when valid params passed' do
    let(:result) { subject.call(params) }

    let(:params) do
      {
        assistance_year: Date.today.year,
        report_types: ['original'],
        allow_list: ['523232'],
        deny_list: ['523232'],
        report_kind: report_kind
      }
    end

    let(:event_name) { 'Successfully published the payload for event with name: events.h411095as.transmission_requested' }

    context 'without a report_kind' do
      let(:report_kind) { nil }

      it 'should publish event successfully' do
        expect(result.success).to eq(event_name)
      end
    end

    context 'with h41_1095a as report_kind' do
      let(:report_kind) { 'h41_1095a' }

      it 'should publish event successfully' do
        expect(result.success).to eq(event_name)
      end
    end

    context 'with h41 as report_kind' do
      let(:report_kind) { 'h41' }

      it 'should publish event successfully' do
        expect(result.success).to eq(event_name)
      end
    end
  end
end

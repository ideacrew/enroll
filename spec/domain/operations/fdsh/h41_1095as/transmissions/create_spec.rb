# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Fdsh::H411095as::Transmissions::Create do
  send(:include, Dry::Monads[:result, :do, :try])
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

    context 'when valid params passed' do
      let(:params) do
        {
          assistance_year: Date.today.year,
          report_types: [:original],
          allow_list: ['523232'],
          deny_list: ['523232']
        }
      end

      let(:success_double) do
        double(success?: true, success: double(publish: true))
      end

      before { allow(subject).to receive(:event).and_return(success_double) }

      it 'should publish event successfully' do
        result = subject.call(params)

        expect(result.success?).to be_truthy
      end
    end
  end
end

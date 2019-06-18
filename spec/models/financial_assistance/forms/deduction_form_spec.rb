# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::DeductionForm, dbclean: :after_each do

  context 'form' do
    context '.initialize' do
      [:id, :kind, :frequency_kind, :amount].each do |attribute|
        it { expect(described_class.new).to respond_to(attribute) }
      end
    end

    context 'attribute values' do
      let(:params) do
        { id: 'id', kind: 'kind', frequency_kind: 'frequency_kind',
          amount: 'amount', start_on: Date.new(2019, 10, 10), end_on: Date.new(2019, 10, 20) }
      end

      let(:deduction_form) { described_class.new(params) }

      it 'should match values as per initialization' do
        [:id, :kind, :frequency_kind, :amount, :start_on, :end_on].each do |attribute|
          expect(deduction_form.send(attribute)).to eq params[attribute]
        end
      end
    end
  end
end

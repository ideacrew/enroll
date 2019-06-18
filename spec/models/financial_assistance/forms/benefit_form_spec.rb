# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::BenefitForm, dbclean: :after_each do

  context 'form' do
    context '.initialize' do
      [:id, :employer_id, :kind, :insurance_kind, :employer_name, :esi_covered].each do |attribute|
        it { expect(described_class.new).to respond_to(attribute) }
      end
    end

    context 'attribute values' do
      let(:params) do
        { id: "id", employer_id: 'employer_id', kind: 'kind', insurance_kind: 'insurance_kind',
          employer_name: 'employer_name', esi_covered: 'esi_covered' }
      end

      let(:benefit_form) { described_class.new(params) }

      it 'should match values as per initialization' do
        [:id, :employer_id, :kind, :insurance_kind, :employer_name, :esi_covered].each do |attribute|
          expect(benefit_form.send(attribute)).to eq attribute.to_s
        end
      end
    end
  end
end

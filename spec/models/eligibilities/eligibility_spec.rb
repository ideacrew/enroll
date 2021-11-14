# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Eligibilities::Eligibility do
  subject { described_class }

  let(:key) { :aca_financial_assistance_renewal_eligibility }
  let(:description) do
    'ACA Financial Assistance Application Annual Renewal Eligibility'
  end
  let(:is_satisfied) { false }
  let(:rrv_ifsv_evidence) do
    Eligibilities::Evidence.new(key: :rrv_ifsv_evidence)
  end
  let(:rrv_non_esi_evidence) do
    Eligibilities::Evidence.new(key: :rrv_non_esi_evidence)
  end
  let(:evidences) { [rrv_ifsv_evidence, rrv_non_esi_evidence] }
  let(:has_unsatisfied_evidences) { true }

  let(:required_params) do
    {
      key: key,
      is_satisfied: is_satisfied,
      evidences: evidences,
      has_unsatisfied_evidences: has_unsatisfied_evidences
    }
  end
  let(:optional_params) { { title: title, description: description } }
  let(:all_params) { required_params.merge(optional_params) }

  context 'Given valid required parameters' do
    subject { described_class.new(required_params) }

    it 'should initialize with unmet satisfied status' do
      expect(subject.is_satisfied).to be_falsey
    end

    it 'should initilize with two evidences each with unmet satisfaction status' do
      expect(subject.evidences.size).to eq evidences.size
      expect(subject.unsatisfied_evidences).to eq subject.evidences
    end

    it 'should be valid and persist to the database' do
      expect(subject.valid?).to be_truthy
      expect(subject.save).to be_truthy

      compare_keys = required_params.keys.reject { |a| a == :evidences }
      compare_params = required_params.reject { |k, v| k == :evidences }

      expect(
        subject
          .serializable_hash(except: :evidences)
          .deep_symbolize_keys
          .slice(*compare_keys)
      ).to eq compare_params
    end
  end
end

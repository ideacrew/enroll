# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Eligibilities::Evidence, type: :model, dbclean: :after_each do
  subject { described_class }

  let(:key) { :rrv_ifsv_evidence }
  let(:title) { 'RRV IRS Income evidence' }
  let(:description) { 'Bulk Renewal Income Verification' }
  let(:received_at) { Time.now - 1.day }
  let(:aasm_state) { 'pending' }
  let(:is_satisfied) { false }
  let(:verification_outstanding) { false }

  let(:required_params) do
    {
      key: key,
      is_satisfied: is_satisfied,
      verification_outstanding: verification_outstanding,
      aasm_state: aasm_state
    }
  end
  let(:optional_params) do
    { title: title, description: description, received_at: received_at }
  end
  let(:all_params) { required_params.merge(optional_params) }

  context 'Given a valid Eligibility parent doc' do
    let(:eligibility_key) { :aca_financial_assistance_renewal_eligibility }
    let(:eligibility_doc) do
      Eligibilities::Eligibility.new(key: eligibility_key)
    end

    it 'should be valid' do
      expect(eligibility_doc.valid?).to be_truthy
    end

    context 'and valid Evidence doc with requird parameters' do
      it 'should persist to the database' do
        evidence_doc = subject.new(required_params)
        eligibility_doc.evidences << evidence_doc

        expect(evidence_doc.valid?).to be_truthy
        expect(eligibility_doc.save).to be_truthy
        expect(eligibility_doc.evidences.count).to eq 1

        expect(
          eligibility_doc
            .evidences
            .first
            .serializable_hash
            .symbolize_keys
            .slice(*required_params.keys)
        ).to eq required_params
      end
    end
  end
end

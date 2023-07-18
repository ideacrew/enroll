# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::IvlOsseEligibility::CreateAdminAttestedEvidence, type: :model, dbclean: :after_each do

  let(:key) { :hc4cc }
  let(:title) { 'childcare subsidy' }
  let(:is_satisfied) { true }
  let(:description) { 'childcare subsidy eligibility' }
  let(:history_params) do
    {
      effective_on: Date.today,
      is_eligible: true,
      from_state: 'draft',
      to_state: 'eligible',
      transition_at: DateTime.now
    }
  end

  let(:required_params) do
    {
      key: key,
      title: title,
      is_satisfied: is_satisfied,
      state_histories: [history_params]
    }
  end

  let(:optional_params) { { description: description } }

  let(:all_params) { required_params.merge(optional_params) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do

    it 'should be success' do
      result = subject.call(all_params)
      expect(result.success?).to be_truthy
    end

    it 'should create evidence' do
      result = subject.call(all_params)
      expect(result.success).to be_a(AcaEntities::People::IvlOsseEligibility::AdminAttestedEvidence)
    end
  end

  context 'when required attributes not passed' do
    it 'should fail with validation error' do
      result = subject.call(required_params.except(:title))
      expect(result.failure?).to be_truthy
      expect(result.failure.error?(:title)).to be_truthy
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Eligible::CreateStateHistory,
               type: :model,
               dbclean: :after_each do

  let(:required_params) do
    {
      effective_on: Date.today,
      is_eligible: true,
      from_state: 'draft',
      to_state: 'eligible',
      transition_at: DateTime.now
    }
  end

  let(:optional_params) do
    {
      event: 'mark_eligible',
      comment: 'hc4cc eligibility submitted',
      reason: 'childcare subsidy'
    }
  end

  let(:all_params) { required_params.merge(optional_params) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do
    context 'when subject is benefit sponsorship' do

      it 'should be success' do
        result = subject.call(all_params)
        expect(result.success?).to be_truthy
      end

      it 'should create eligibility' do
        result = subject.call(all_params)
        expect(result.success).to be_a(AcaEntities::Eligible::StateHistory)
      end
    end
  end

  context 'when required attributes not passed' do
    it 'should fail with validation error' do
      result = subject.call(required_params.except(:effective_on))
      expect(result.failure?).to be_truthy
      expect(result.failure.error?(:effective_on)).to be_truthy
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

#spec for RidpEligibilityResponseContract
module Validators
  RSpec.describe Validators::RidpEligibilityResponseContract do
    let(:primary_member_hhx_id) { '2345667789' }
    let(:event_kind) { 'primary' }
    let(:delivery_info) { '2345667789' }
    let(:metadata) { '2345667789' }
    let(:event) { '2345667789' }
    let(:created_at) { Time.now }
    let(:deleted_at) { nil }

    let(:ridp_eligibility) do
      { delivery_info: delivery_info, metadata: metadata, event: event }
    end

    let(:required_params) { { primary_member_hbx_id: primary_member_hbx_id } }

    let(:optional_params) do
      {
        event_kind: event_kind,
        ridp_eligibility: ridp_eligibility,
        created_at: created_at,
        deleted_at: deleted_at
      }
    end

    let(:all_params) { required_params.merge(optional_params) }

    context 'Invalid parameters' do
      context 'No required or optional parameters' do
        result = describe_class.new.call({})
        expect(result.failure?).to be_truthy
      end

      contecxt 'Optional parameters only' do
        result = describe_class.new.call(optional_params)
        expect(result.failure?).to be_truthy
      end
    end
    context 'Valid parameters' do
      context 'Required params only' do
        result = describe_class.new.call(required_params)
        expect(result.success?).to be_truthy
        expect(result.value.to_h).to eq required_params
      end

      context 'Required and optional (All) params' do
        it 'should validate' do
          result = describe_class.new.call(all_params)
          expect(result.success?).to be_truthy
          expect(result.value.to_h).to eq all_params
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::ExpirationHandler, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family) }

  describe 'with invalid params' do
    let(:params) { {} }
    let(:result) { described_class.new.call(params) }

    it 'fails due to missing enrollment hbx id' do
      expect(result.success?).to be_falsey
      expect(result.failure).to eq('Missing query_criteria')
    end
  end

  describe 'with invalid query criteria' do
    let(:params) { { query_criteria: { 'bad query'} } }
    let(:result) { described_class.new.call(params) }

    it 'fails due to invalid enrollment kind' do
      expect(result.success?).to be_falsey
      expect(result.failure).to eq(/Error generating enrollments_to_expire query/)
    end
  end

  describe 'with valid params' do
    let(:params) { { query_criteria: enrollment.hbx_id } }
    let(:result) { described_class.new.call(params) }

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Done publishing enrollment expiration events.  See hbx_enrollments_expiration_handler log for results.")
    end
  end
end

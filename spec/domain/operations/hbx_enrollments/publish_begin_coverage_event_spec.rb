# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::PublishBeginCoverageEvent, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, aasm_state: "auto_renewing") }

  describe 'with invalid params' do
    let(:result) { described_class.new.call(params) }

    context 'params is not a hash' do
      let(:params) { 'bad params' }

      it 'fails due to missing query criteria' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq("Invalid input params: #{params}.")
      end
    end

    context 'missing enrollment hbx id' do
      let(:params) { {} }

      it 'fails due to missing query criteria' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq("Invalid input params: #{params}.")
      end
    end
  end

  describe 'with valid params' do
    let(:params) { { enrollment: enrollment } }
    let(:result) { described_class.new.call(params) }

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Successfully published begin coverage event.")
    end
  end
end

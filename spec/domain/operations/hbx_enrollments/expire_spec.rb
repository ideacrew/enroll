# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::Expire, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family) }

  describe 'with invalid params' do
    let(:params) { {} }
    let(:result) { described_class.new.call(params) }

    it 'fails due to missing enrollment hbx id' do
      expect(result.success?).to be_falsey
      expect(result.failure).to eq('Missing enrollment_hbx_id')
    end
  end

  describe 'with invalid enrollment' do
    let(:params) { { enrollment_hbx_id: enrollment.hbx_id } }
    let(:result) { described_class.new.call(params) }

    describe 'where enrollment is not an ivl enrollment' do
      before do
        enrollment.update(kind: 'employer_sponsored')
      end

      it 'fails due to invalid enrollment kind' do
        expect(result.success?).to be_falsey
        expect(result.failure).to eq("Unable to expire enrollment hbx id #{enrollment.hbx_id} - employer_sponsored is not a valid IVL enrollment kind")
      end
    end
  end

  describe 'with valid params' do
    let(:params) { { enrollment_hbx_id: enrollment.hbx_id } }
    let(:result) { described_class.new.call(params) }

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Successfully expired enrollment hbx id #{enrollment.hbx_id}")
    end
  end
end

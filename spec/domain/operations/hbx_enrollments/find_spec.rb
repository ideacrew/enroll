# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::Find, dbclean: :after_each do

  let(:family)              { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment)            { FactoryBot.create(:hbx_enrollment, family: family) }

  describe 'find enrollment' do
    let(:valid_params) { { id: enrollment.id.to_s } }
    let(:invalid_params) { { id: BSON::ObjectId.new.to_s } }

    it 'should return enrollment record' do
      result = subject.call(valid_params)

      expect(result.success?).to be_truthy
      expect(result.success).to be_a HbxEnrollment
    end

    it 'should throw an error' do
      result = subject.call(invalid_params)

      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Enrollment not found")
    end
  end
end

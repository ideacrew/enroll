# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Policies::BuildCv3FamilyFromPolicy, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }

  describe 'with Invalid policy(enrollment) ID' do
    it "fail with invalid enrollment " do
      result = described_class.new.call({policy_id: "12345"})
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Enrollment not found")
    end
  end

  describe 'with valid params' do
    it "success with correct family" do
      result = described_class.new.call({policy_id: enrollment.hbx_id})
      expect(result.success?).to be_truthy
    end
  end
end

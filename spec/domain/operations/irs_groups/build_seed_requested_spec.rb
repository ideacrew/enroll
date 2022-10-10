# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::IrsGroups::BuildSeedRequest, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }

  describe 'with Invalid family ID' do
    it "failes with invalid enrollment " do
      result = described_class.new.call("123456")
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Unable to find Family with ID 123456.")
    end
  end

  describe 'with valid params' do
    it "success with correct family" do
      result = described_class.new.call(family.id)
      expect(result.success?).to be_truthy
    end
  end
end

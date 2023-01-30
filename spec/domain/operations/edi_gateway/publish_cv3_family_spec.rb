# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::EdiGateway::PublishCv3Family, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }

  describe 'with Invalid person hbx ID' do
    it "fail with invalid person hbx ID" do
      result = described_class.new.call({ person_hbx_id: "12345" })
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Unable to find person")
    end
  end

  describe 'with valid params' do
    it "success with correct family" do
      result = described_class.new.call({ person_hbx_id: family.primary_person.hbx_id, year: 2022 })
      expect(result.success?).to be_truthy
    end
  end
end

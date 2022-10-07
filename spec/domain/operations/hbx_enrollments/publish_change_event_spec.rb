# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::PublishChangeEvent, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }

  describe 'with Invalid params' do
    it "failes with invalid enrollment " do
      invalid_params = {event_name: 'auto_renew', enrollment: "dummy"}
      result = described_class.new.call(invalid_params)
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Invalid Enrollment object dummy")
    end

    it "failes with invalid event_name " do
      invalid_params = {event_name: 'test_event', enrollment: enrollment}
      result = described_class.new.call(invalid_params)
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Invalid event_name test_event")
    end
  end

  describe 'with valid params' do
    it "failes with invalid enrollment " do
      valid_params = {event_name: 'auto_renew', enrollment: enrollment}
      result = described_class.new.call(valid_params)
      expect(result.success?).to be_truthy
    end
  end
end

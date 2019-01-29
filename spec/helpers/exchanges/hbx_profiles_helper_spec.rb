require "rails_helper"

RSpec.describe Exchanges::HbxProfilesHelper, dbclean: :after_each, :type => :helper do

  context 'for force_publish_warning_message' do
    before :each do
      @warning_message ||= helper.force_publish_warning_message
    end

    it 'should return false' do
      expect(@warning_message).not_to include('Employer attestation documentation not provided. Select Documents on the blue menu to the left and follow the instructions to upload your documents.')
    end

    it 'should return true' do
      expect(@warning_message).to include('Employer attestation documentation not provided')
    end

    it 'should return true' do
      expect(@warning_message).to include('At least one employee must be assigned to the benefit package')
    end

    it 'should return true' do
      expect(@warning_message).to include('Employer Plan Year must have a reference plan and Health product benefit package.')
    end
  end
end

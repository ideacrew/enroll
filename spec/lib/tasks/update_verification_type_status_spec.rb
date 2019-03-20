require 'rails_helper'
require 'rake'

RSpec.describe 'update_verification_type_status' do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:consumer) { person.consumer_role }
  let(:verification_types) { consumer.verification_types }

  before do
    load File.expand_path("#{Rails.root}/lib/tasks/update_verification_type_status.rake", __FILE__)
    Rake::Task.define_task(:environment)
  end

  context "Update verification type status" do
 
    it "Should move to verified when status is pending" do
      ENV['hbx_id'] = person.hbx_id
      ENV['verification_type_name'] = "DC Residency"
      person.verification_types.by_name("DC Residency").first.update_attributes(validation_status: "pending")
      Rake::Task["migrations:update_verification_type_status"].invoke()
      person.reload
      expect(person.verification_types.by_name("DC Residency").first.validation_status).to eq "verified"
    end

    it "Should not move to verified when status is not pending" do
      ENV['hbx_id'] = person.hbx_id
      ENV['verification_type_name'] = "DC Residency"
      person.verification_types.by_name("DC Residency").first.update_attributes(validation_status: "unverified")
      Rake::Task["migrations:update_verification_type_status"].invoke()
      person.reload
      expect(person.verification_types.by_name("DC Residency").first.validation_status).not_to eq "verified"
    end
  end
end

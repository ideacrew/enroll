require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_consumer_identity_verification")

describe UpdateConsumerIdentityVerification do

  let(:given_task_name) { "update_consumer_identity_verification" }
  subject { UpdateConsumerIdentityVerification.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "update identity verification on a consumer" do
    let!(:person1) { FactoryGirl.create(:person, :with_consumer_role) }
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person1.hbx_id)
    end

    it "should clone consumer role from person1 to person1" do
      person1.consumer_role.bookmark_url
      subject.migrate
      expect(person1.consumer_role).not_to eq (person1.consumer_role.bookmark_url)
    end
  end
end
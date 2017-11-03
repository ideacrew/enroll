require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "trigger_broker_invitation_url")

describe TriggerBrokerInvitationUrl, dbclean: :after_each do
  let(:given_task_name) {"trigger_broker_invitation"}
  subject {TriggerBrokerInvitationUrl.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person ssn" do
    let(:person) {FactoryGirl.build(:person)}
    let(:registered_broker_role) {BrokerRole.new(person: person, npn: "2323334", provider_kind: "broker")}

    before do
      $stdout = StringIO.new
      allow(registered_broker_role).to receive(:is_primary_broker?).and_return(true)
      registered_broker_role.approve
      allow(ENV).to receive(:[]).with("broker_npn").and_return(registered_broker_role.npn)
    end

    after(:all) do
      $stdout = STDOUT
    end

    it "should Trigger URL Invitation" do
      subject.migrate
      expect($stdout.string).to match("Invitation sent")
    end
  end
end

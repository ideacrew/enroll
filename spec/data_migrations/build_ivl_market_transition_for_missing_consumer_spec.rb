require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "build_ivl_market_transition_for_missing_consumer")

describe BuildIvlMarketTransitionForMissingConsumer do

  let(:given_task_name) { "build_individual_market_transition_for_missing_consumer" }
  subject { BuildIvlMarketTransitionForMissingConsumer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "build consumer individual market transitions with role_type consumer" do

    let!(:person) {FactoryGirl.create(:person, :with_consumer_role)}
    before(:each) do
      allow(ENV).to receive(:[]).with("action").and_return "build_ivl_transitions"
      allow(ENV).to receive(:[]).with("hbx_id").and_return person.hbx_id
    end

    it "should build individual market transitions for only people with consumer role" do
      subject.migrate
      person.reload
      expect(person.individual_market_transitions.present?).to eq true
    end
  end
end

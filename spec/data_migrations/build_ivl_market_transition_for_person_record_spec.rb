require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "build_ivl_market_transition_for_person_record")

describe BuildIvlMarketTransitionForPersonRecord do

  let(:given_task_name) { "build_individual_market_transition_for_person_record" }
  subject { BuildIvlMarketTransitionForPersonRecord.new(given_task_name, double(:current_scope => nil)) }

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

  describe "build consumer individual market transitions with role_type resident" do
    let!(:person) {FactoryGirl.create(:person, :with_resident_role)}
    before(:each) do
      allow(ENV).to receive(:[]).with("action").and_return "build_resident_transitions"
      allow(ENV).to receive(:[]).with("hbx_id").and_return person.hbx_id
    end

    it "should build individual market transitions for only people with resident role" do
      expect(person.individual_market_transitions.present?).to eq false
      subject.migrate
      person.reload
      expect(person.individual_market_transitions.present?).to eq true
    end
  end
end

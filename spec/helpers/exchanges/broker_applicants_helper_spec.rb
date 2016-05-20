require "rails_helper"

RSpec.describe Exchanges::BrokerApplicantsHelper, :type => :helper do
  context "sort_by_latest_transition_time" do
    let(:person1) {FactoryGirl.create(:person, :with_broker_role)}
    let(:person2) {FactoryGirl.create(:person, :with_broker_role)}
    let(:person3) {FactoryGirl.create(:person, :with_broker_role)}
    let(:people) {[person1, person2, person3]}

    before do
      allow(person1.broker_role).to receive(:latest_transition_time).and_return(Time.now)
      allow(person2.broker_role).to receive(:latest_transition_time).and_return(Time.now - 5.days)
      allow(person3.broker_role).to receive(:latest_transition_time).and_return(Time.now - 2.days)
    end

    it "returns people array sorted by broker_role.latest_transition_time" do
      expect(helper.sort_by_latest_transition_time(people)).to eq([person2, person3, person1])
    end
  end
end

require "rails_helper"

RSpec.describe TimeHelper, :type => :helper do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }

  before :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  describe "time remaining in words" do
    it "counts 95 days from the passed in date" do
      expect(helper.time_remaining_in_words(TimeKeeper.date_of_record)).to eq("95 days")
    end
  end
end

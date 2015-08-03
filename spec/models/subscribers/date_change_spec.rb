require "rails_helper"

describe Subscribers::DateChange do
  it "should subscribe to the correct event" do
    expect(Subscribers::DateChange.subscription_details).to eq ["acapi.info.events.calendar.date_change"]
  end

  describe "given a message to handle" do
    let(:date_string) { "2015-02-17" }
    let(:expected_date) { Date.new(2015, 2, 17) }

    describe "that has a current date with a string key" do
      let(:message) { { "current_date" => date_string } }

      it "should update the timekeeper" do
        expect(TimeKeeper).to receive(:set_date_of_record).with(expected_date)
        subject.call(nil, nil, nil, nil, message)
      end
    end

    describe "that has a current date with a symbol key" do
      let(:message) { { :current_date => date_string } }

      it "should update the timekeeper" do
        expect(TimeKeeper).to receive(:set_date_of_record).with(expected_date)
        subject.call(nil, nil, nil, nil, message)
      end
    end
  end
end

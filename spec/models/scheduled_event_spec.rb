require 'rails_helper'

RSpec.describe ScheduledEvent, type: :model do
  subject { ScheduledEvent.new }

  it "has a valid factory" do
    expect(create(:scheduled_event)).to be_valid
  end

  it { is_expected.to validate_presence_of :type }
  it { is_expected.to validate_presence_of :event_name }
  it { is_expected.to validate_presence_of :one_time }
  it { is_expected.to validate_presence_of :start_time }
  it { is_expected.to validate_presence_of :offset_rule }

  context "convert recurring rules into hash" do
  	let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}",
      :start_time => Date.today
    }}
    value = "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}"
  	let(:scheduled_event1) {ScheduledEvent.new(event_params)}
  	recurring_hash = {:validations=>{:day_of_month=>[22]}, :rule_type=>"IceCube::MonthlyRule", :interval=>1}
  	it "convert recurring rules into hash" do
  	  expect(scheduled_event1.recurring_rules).to eq recurring_hash
  	end
  end
  context "set start time to current if entered value is blank" do
  	value = ""
  	let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}",
      :start_time => value
    }}
  	let(:scheduled_event1) {ScheduledEvent.new(event_params)}
  	it "set start time to current if entered value is blank" do
  	  expect(scheduled_event1.start_time).to eq TimeKeeper.date_of_record
  	end
  end
  context "set start time value is entered" do
  	value = "05/24/2017"
  	let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}",
      :start_time => value
    }}
  	let(:scheduled_event1) {ScheduledEvent.new(event_params)}
  	it "set start time value is entered" do
  	  expect(scheduled_event1.start_time).to eq Date.strptime(value, "%m/%d/%Y").to_date
  	end
  end
end

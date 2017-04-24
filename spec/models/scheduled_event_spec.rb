require 'rails_helper'

RSpec.describe ScheduledEvent, type: :model do
  subject { ScheduledEvent.new }

  it "has a valid factory" do
    expect(create(:scheduled_event)).to be_valid
  end

  it { is_expected.to validate_presence_of :type }
  it { is_expected.to validate_presence_of :event_name }
  it { is_expected.to validate_presence_of :one_time }
  it { is_expected.to validate_presence_of :start_date }
end
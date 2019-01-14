FactoryBot.define do
  factory :event_exception do
    scheduled_event  { FactoryBot.build(:scheduled_event) }
    time             { Date.new(2017, 8, 2) }
  end
end
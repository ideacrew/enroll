# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_process_state, class: "::Transmittable::ProcessState" do
    event {"initial"}
    state_key {:initial}
    started_at {DateTime.now}
    message {"initial"}
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_process_status, class: "::Transmittable::ProcessStatus" do
    initial_state_key {:initial}
    latest_state {:initial}
  end
end

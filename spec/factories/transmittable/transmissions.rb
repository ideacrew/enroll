# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_transmission, class: "::Transmittable::Transmission" do
    started_at  { DateTime.now }
    key { :ssa_verification_request }
    process_status  { { initial_state_key: :initial, states: [{ event: "initial", state_key: :initial }] } }
    transmission_id { "test_transmission_123" }
  end
end

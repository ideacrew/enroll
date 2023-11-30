# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_job, class: "::Transmittable::Job" do
    key {:ssa_verification_request}
    started_at {DateTime.now}
    publish_on {DateTime.now}
    job_id {"Job_123"}
  end
end

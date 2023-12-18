# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_job, class: "::Transmittable::Job" do
    key {:ssa_verification_request}
    started_at {DateTime.now}
    publish_on {DateTime.now}
    job_id {"Job_123"}

    trait :hbx_enrollments_expiration do
      key { :hbx_enrollments_expiration }
      title { "Request expiration of all active IVL enrollments before #{TimeKeeper.date_of_record.beginning_of_year}." }
      description { "Job that requests expiration of all active IVL enrollments before #{TimeKeeper.date_of_record.beginning_of_year}." }
      publish_on { DateTime.now }
      started_at { DateTime.now }
      job_id { nil }
    end
  end
end

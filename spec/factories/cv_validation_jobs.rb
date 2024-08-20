# frozen_string_literal: true

# Factory for creating instances of CvValidationJob for testing purposes.
FactoryBot.define do
  factory :cv_validation_job, class: 'CvValidationJob'  do
    cv_payload { 'Sample CV Payload' }
    cv_version { '3' }
    aca_version { '1.0.0' }
    aca_entities_sha { 'abc123' }
    primary_person_hbx_id { '98765' }
    family_hbx_id { '12345' }
    family_updated_at { DateTime.now }
    job_id { 'job_123' }
    cv_errors { [] }
    logging_messages { [] }
    cv_start_time { DateTime.now - 60.minutes }
    cv_end_time { DateTime.now - 1.minute }
    start_time { DateTime.now - 61.minutes }
    end_time { DateTime.now }

    trait :success do
      result { :success }
    end

    trait :failure do
      result { :failure }
      cv_errors { ["Error 1", "Error 2"] }
    end

    trait :with_logging_messages do
      logging_messages { ["Log message 1", "Log message 2"] }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :people_eligibilities_event_log, class: 'People::EligibilitiesEventLog' do
    subject_gid { "some_subject_gid" }
    event_name { "some_event_name" }
    event_category { :login }
    event_time { Time.now }
    host_id { "some_host_id" }
    payload { "some_payload" }
    event_outcome { "some_event_outcome" }
    correlation_id { "some_correlation_id" }
  end
end

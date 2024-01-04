# frozen_string_literal: true

FactoryBot.define do
  factory :monitored_event, class: 'EventLogs::MonitoredEvent' do
    account_hbx_id { "100001"}
    account_username { "test_user"}
    subject_hbx_id { "100002"}
    event_category { :login }
    event_time { Time.now }
    login_session_id { "1234567890"}
  end
end

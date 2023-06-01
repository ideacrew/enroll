# frozen_string_literal: true

FactoryBot.define do
  factory :audit_log_event, class: 'AuditLogEvent' do
    sequence(:subject_gid) do |n|
      "gid://enroll/FamilyMember/6156ad4c0319b0018#{n}"
    end
    sequence(:correlation_id) { |n| "a156ad4c031#{n}" }
    sequence(:session_id) { |n| "222_222_220#{n}" }
    sequence(:account_id) { |n| "d156ad4c031#{n}" }
    host_id { :enroll }
    event_category { :osse_eligibility }
    trigger { 'determine_eligibility' }
    response { 'success' }
    log_level { :debug }
    severity { :debug }
    sequence(:event_time) { |n| 2.days.ago + n.minutes }
  end
end

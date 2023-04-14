# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuditLogEvent, type: :model, dbclean: :around_each do
  before { DatabaseCleaner.clean }

  describe '.save' do
    let(:params) do
      {
        subject_gid: 'gid://enroll/FamilyMember/6156ad4c0319b00185',
        correlation_id: 'a156ad4c031',
        session_id: '222_222_220',
        account_id: 'd156ad4c031g32324tf0',
        host_id: :enroll,
        event_category: :osse_eligibility,
        trigger: 'determine_eligibility',
        response: 'success',
        log_level: :debug,
        severity: :debug,
        event_time: DateTime.new
      }
    end

    it "should persist record" do
      audit_event = described_class.new(params)
      audit_event.save

      expect(AuditLogEvent.count).to eq 1
    end
  end

  describe 'when audit log events already present' do
    let!(:audit_events) { create_list(:audit_log_event, 10) }

    context '.events_during' do
      let(:time_period) do
        audit_events[0].event_time..audit_events[5].event_time
      end

      it 'should return events by time period' do
        results = described_class.events_during(time_period)

        expect(results.count).to eq 6
        expect(results).to eq audit_events[0..5]
      end
    end

    context '.by_event_category' do
      it 'should return events by category' do
        expect(
          described_class.by_event_category(:osse_eligibility).count
        ).to eq 10
      end
    end

    context '.by_log_level' do
      let!(:error_events) do
        audit_events[5..7].each { |event| event.update(log_level: :error) }
      end

      it 'should return events by log level' do
        expect(described_class.by_log_level(:error).count).to eq 3
        expect(described_class.by_log_level(:debug).count).to eq 7
      end
    end
  end
end

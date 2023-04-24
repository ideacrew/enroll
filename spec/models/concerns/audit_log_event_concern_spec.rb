# frozen_string_literal: true

require 'rails_helper'

class DummyClass
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification
  include AuditLogEventConcern
end

RSpec.describe AuditLogEventConcern, type: :model, dbclean: :around_each do
  before { DatabaseCleaner.clean }

  let!(:subjects) do
    5.times do
      subject = DummyClass.new
      subject.save
    end
  end

  let!(:audit_log_events) do
    DummyClass.each do |subject|
      create(
        :audit_log_event,
        subject_gid: subject.to_gid.to_s,
        event_time: subject.created_at.time
      )
    end
  end

  let!(:other_events) do
    create_list(:audit_log_event, 5, event_time: DateTime.now - 2.minutes)
  end

  describe 'class methods' do
    subject { DummyClass }

    context '.audit_log_events' do
      it 'should return all events by subject prefix' do
        expect(AuditLogEvent.count).to eq 10
        expect(subject.audit_log_events.count).to eq 5
      end
    end

    context '.audit_log_events_during' do
      let(:time_period) do
        DummyClass.first.created_at.time..DummyClass.last.created_at.time
      end

      it 'should return all events by subject prefix and time period' do
        expect(AuditLogEvent.count).to eq 10
        expect(subject.audit_log_events_during(time_period).count).to eq 5
      end
    end
  end

  describe 'instance methods' do
    subject { DummyClass.last }

    context '.audit_log_events' do
      it 'should return all events by subject' do
        expect(subject.audit_log_events.count).to eq 1
        expect(
          subject.audit_log_events.first.subject_gid
        ).to eq subject.to_gid.to_s
      end
    end

    context '.audit_log_events_during' do
      let(:time_period) { (subject.created_at - 5.minutes).time..subject.created_at.time }

      it 'should return all events by subject and time period' do
        expect(subject.audit_log_events_during(time_period).count).to eq 1
        expect(
          subject.audit_log_events_during(time_period).first.subject_gid
        ).to eq subject.to_gid.to_s
      end
    end
  end
end

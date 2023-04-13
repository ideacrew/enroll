# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::AuditLogEvents::Build,
               type: :model,
               dbclean: :after_each do
  let(:params) do
    {
      subject_gid: 'gid://enroll/FamilyMember/6156ad4c0319b00185',
      correlation_id: 'a156ad4c031',
      session_id: '222_222_220',
      account_id: 'd156ad4c031g32324tf0',
      host_id: 'enroll',
      event_category: :osse_eligibility,
      trigger: 'determine_eligibility',
      response: 'success',
      log_level: :debug,
      severity: :debug,
      event_time: DateTime.new
    }
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do
    it 'should be success' do
      result = subject.call(params)
      expect(result.success?).to be_truthy
    end

    it 'should return entity' do
      result = subject.call(params)

      expect(result.success).to be_an_instance_of(AcaEntities::AuditLogs::AuditLogEvent)
    end
  end

  context 'when required attributes not passed' do

    it 'should fail with errors on required attributes' do
      result = subject.call(params.except(:subject_gid, :event_category, :log_level))
      expect(result.failure?).to be_truthy
      errors = result.failure.errors.to_h
      expect(errors.key?(:subject_gid)).to be_truthy
      expect(errors.key?(:event_category)).to be_truthy
      expect(errors.key?(:log_level)).to be_falsey
    end
  end
end

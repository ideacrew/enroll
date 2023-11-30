# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Transmittable::FindOrCreateJob, dbclean: :after_each do
  subject { described_class.new }
  let(:key) { :ssa_verification_request}
  let(:title) { 'SSA Verification Request'}
  let(:description) { 'Request for SSA verification to CMS'}
  let(:payload) { { message: "A REQUEST PAYLOAD" } }

  let(:required_params) do
    {
      key: key,
      started_at: DateTime.now,
      publish_on: DateTime.now
    }
  end

  let(:optional_params) do
    {
      title: title,
      description: description,
      payload: payload
    }
  end

  let(:all_params) { required_params.merge(optional_params) }

  context 'sending invalid params' do
    it 'should return a failure with missing key' do
      result = subject.call(required_params.except(:key))
      expect(result.failure).to eq('key required')
    end

    it 'should return a failure when key is not a symbol' do
      required_params[:key] = "Key"
      result = subject.call(required_params)
      expect(result.failure).to eq('key required')
    end

    it 'should return a failure with missing started_at' do
      result = subject.call(required_params.except(:started_at))
      expect(result.failure).to eq('started_at required')
    end

    it 'should return a failure when started_at is not a Datetime' do
      required_params[:started_at] = Date.today
      result = subject.call(required_params)
      expect(result.failure).to eq('started_at required')
    end

    it 'should return a failure with missing publish_on' do
      result = subject.call(required_params.except(:publish_on))
      expect(result.failure).to eq('publish_on required')
    end

    it 'should return a failure when publish_on is not a Datetime' do
      required_params[:publish_on] = Date.today
      result = subject.call(required_params)
      expect(result.failure).to eq('publish_on required')
    end
  end

  context 'when there is an existing job' do
    let!(:job) { create(:transmittable_job) }

    it 'should return the existing job when job_id is provided' do
      result = subject.call(required_params.merge(job_id: job.job_id))
      expect(result.value!).to eq job
    end

    it 'should return the existing job when message_id is provided' do
      job.update(message_id: '1234')
      result = subject.call(required_params.merge(message_id: job.message_id))
      expect(result.value!).to eq job
    end
  end

  context 'sending valid params' do
    before do
      @result = subject.call(all_params)
    end

    it "Should not have any errors" do
      expect(@result.success?).to be_truthy
    end

    it 'should generate a job' do
      expect(@result.value!.class).to eq Transmittable::Job
    end

    it 'should generate a job_id' do
      expect(@result.value!.job_id).not_to be_nil
    end
  end
end

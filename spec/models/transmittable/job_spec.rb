# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transmittable::Job, type: :model, dbclean: :after_each do
  let(:job) { FactoryBot.create(:transmittable_job) }

  describe '#before_create' do
    it 'populates message_id for the job' do
      expect(job.message_id).to be_present
    end
  end

  describe '#to_global_id' do
    it 'responds to to_global_id' do
      expect(job.respond_to?(:to_global_id)).to be_truthy
    end

    it 'returns the GlobalID URI' do
      expect(
        job.to_global_id.uri.to_s
      ).to eq("gid://enroll/#{described_class}/#{job.id}")
    end
  end
end

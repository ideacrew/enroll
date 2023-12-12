# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::RequestExpirations, dbclean: :after_each do
  describe '#call' do
    let(:logger) do
      "#{Rails.root}/log/request_expirations_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    end

    let(:logger_content) { File.read(logger) }

    let(:result) { subject.call({}) }

    let(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

    let(:start_on) do
      hbx_profile.benefit_sponsorship.current_benefit_coverage_period.start_on
    end

    let(:event_name) { 'events.individual.enrollments.expire_coverages.request' }

    let(:success_msg) do
      "Successfully published event: #{event_name} to request expiration of all active IVL enrollments effective before #{start_on}."
    end

    context 'with valid params' do
      before do
        start_on
        result
      end

      it 'returns success' do
        expect(result.success).to eq(success_msg)
      end

      it 'logs success message' do
        expect(logger_content).to include(success_msg)
      end

      it 'creates a job' do
        expect(subject.job).to be_a(Transmittable::Job)
      end
    end

    context 'with invalid params' do
      context 'when params is not a hash' do
        let(:params) { nil }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when enrollment is not a valid object' do
        let(:params) { { enrollment: 'enrollment' } }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when job is not a valid object' do
        let(:params) { { enrollment: enrollment, job: 'transmittable_job' } }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end
    end
  end

  after :all do
    file_path = "#{Rails.root}/log/request_expirations_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(file_path) if File.file?(file_path)
  end
end

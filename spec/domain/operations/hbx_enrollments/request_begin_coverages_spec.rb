# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::RequestBeginCoverages, dbclean: :after_each do
  describe '#call' do
    let(:result) { subject.call({}) }

    # TODO: Refactor to get the logger content from subject.logger instead of hardcoding the path
    let(:logger_content) do
      File.read("#{Rails.root}/log/request_begin_coverages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end

    let(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

    let(:benefit_coverage_period) do
      hbx_profile.benefit_sponsorship.current_benefit_coverage_period
    end

    let(:start_on) { benefit_coverage_period.start_on }

    let(:event_name) { 'events.individual.enrollments.begin_coverages.request' }

    let(:success_msg) do
      "Successfully published event: #{event_name} to request begin coverage for all IVL renewal enrollments for the year #{start_on.year}."
    end

    context 'with valid params' do
      before do
        benefit_coverage_period
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
      context 'without hbx profile' do
        it 'returns a failure moand with error message' do
          expect(result.failure).to eq('Unable to find start_on and end_on for the current benefit coverage period.')
        end
      end
    end
  end

  after :all do
    file_path = "#{Rails.root}/log/request_begin_coverages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(file_path) if File.file?(file_path)
  end
end

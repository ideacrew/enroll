# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::RequestExpirations, dbclean: :after_each do
  describe '#call' do
    let(:result) { subject.call({}) }

    # TODO: Refactor to get the logger content from subject.logger instead of hardcoding the path
    let(:logger_content) do
      File.read("#{Rails.root}/log/request_expirations_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end

    let(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

    let(:start_on) do
      hbx_profile.benefit_sponsorship.current_benefit_coverage_period.start_on
    end

    let(:event_name) { 'events.individual.enrollments.expire_coverages.request' }

    let(:success_msg) do
      "Successfully published event: #{event_name} to request expiration of all active IVL enrollments effective before #{start_on}."
    end

    context 'with valid params' do
      let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family,
                                                                   effective_on: start_on - 1.month)
      end

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

    context 'no enrollments to expire' do
      before do
        start_on
        result
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to match(/No enrollments found for query criteria/)
      end

      it 'not creates a job' do
        expect(subject.job).to eq nil
      end
    end

    context 'with invalid params' do
      context 'without hbx profile' do
        it 'returns a failure monad with error message' do
          expect(result.failure).to eq('Unable to find the start_on date for current benefit coverage period.')
        end
      end
    end
  end

  after :all do
    file_path = "#{Rails.root}/log/request_expirations_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(file_path) if File.file?(file_path)
  end
end

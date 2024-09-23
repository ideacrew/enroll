# frozen_string_literal: true

RSpec.describe Operations::Migrations::Applications::BenchmarkPremiums::Populate, type: :model do
  include Dry::Monads[:result]

  after :all do
    DatabaseCleaner.clean

    # Deletes all the log files created during the test
    Dir.glob("#{Rails.root}/log/benchmark_premiums_migration_populator_*.log").each do |file|
      File.delete(file)
    end
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:primary_applicant) { family.primary_applicant }

  let(:application_aasm_state) { 'determined' }

  let(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      family: family,
      effective_date: TimeKeeper.date_of_record.beginning_of_year,
      aasm_state: application_aasm_state
    )
  end

  let(:applicant_benchmark_premiums) { {} }

  let(:applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      application: application,
      person_hbx_id: person.hbx_id,
      family_member_id: primary_applicant.id,
      benchmark_premiums: applicant_benchmark_premiums
    )
  end

  describe '#call' do
    let(:benchmark_premiums_result) do
      Success(
        {
          health_only_slcsp_premiums: [{ member_identifier: person.hbx_id, monthly_premium: 100.0 }],
          health_only_lcsp_premiums: [{ member_identifier: person.hbx_id, monthly_premium: 90.0 }]
        }
      )
    end

    before :each do
      applicant
      allow(subject).to receive(:fetch_benchmark_premiums).with(application).and_return(
        benchmark_premiums_result
      )
    end

    context 'with valid params' do
      let(:params) { { application_id: application.id } }

      it 'returns success' do
        expect(subject.call(params).success).to eq(
          "Successfully populated benchmark premiums for application: #{application.id}."
        )
        expect(
          applicant.reload.benchmark_premiums.deep_symbolize_keys
        ).to eq(benchmark_premiums_result.success)
      end
    end

    context 'missing params' do
      let(:params) { {} }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input application id: #{params[:application_id]}."
        )
      end
    end

    context 'missing value for application_id' do
      let(:params) { { application_id: nil } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Invalid input application id: #{params[:application_id]}."
        )
      end
    end

    context 'invalid application_id' do
      let(:params) { { application_id: BSON::ObjectId.new } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Application not found for id: #{params[:application_id]}"
        )
      end
    end

    context 'application is not in a valid state for processing' do
      let(:application_aasm_state) { 'draft' }
      let(:params) { { application_id: application.id } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Application is not in a valid state for processing: #{application_aasm_state} or benchmark premiums already exist."
        )
      end
    end

    context 'benchmark premiums already exist' do
      let(:applicant_benchmark_premiums) { benchmark_premiums_result.success.deep_stringify_keys }
      let(:params) { { application_id: application.id } }

      it 'returns failure' do
        expect(subject.call(params).failure).to eq(
          "Application is not in a valid state for processing: #{application_aasm_state} or benchmark premiums already exist."
        )
      end
    end
  end
end

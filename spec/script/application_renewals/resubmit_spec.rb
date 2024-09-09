# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'resubmit', dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    file_path = Dir["#{Rails.root}/resubmit_renewal_applications_*.csv"].first
    FileUtils.rm_rf(file_path) if file_path.present?
  end

  let(:file_path) { Dir["#{Rails.root}/resubmit_renewal_applications_*.csv"].first }
  let(:current_year) { TimeKeeper.date_of_record.year }
  let(:renewal_year) { current_year.next }
  let(:person) do
    FactoryBot.create(:person, :with_consumer_role, first_name: 'test10', last_name: 'test30', gender: 'male', hbx_id: '100095')
  end
  let(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: person)
  end
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111000222',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      aasm_state: 'determined',
                      assistance_year: current_year,
                      full_medicaid_determination: true)
  end
  let!(:renewal_draft_application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111222333',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      aasm_state: 'renewal_draft',
                      assistance_year: renewal_year,
                      full_medicaid_determination: true)
  end
  let!(:submitted_application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111222333',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      aasm_state: 'submitted',
                      assistance_year: renewal_year,
                      full_medicaid_determination: true)
  end
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year}
  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      kind: "individual",
                      coverage_kind: "health",
                      aasm_state: 'coverage_selected',
                      effective_on: effective_on,
                      hbx_enrollment_members: [
                        FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: effective_on, coverage_start_on: effective_on, is_subscriber: true)
                      ])
  end
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      person_hbx_id: '100095',
                      is_primary_applicant: true,
                      family_member_id: family.primary_applicant.id,
                      first_name: 'Test',
                      last_name: 'Applicant',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                      application: application)
  end
  let(:operation_double) { double }
  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
  end

  context 'missing renewal_year' do
    let(:renewal_year) { nil }

    it 'prints a failure message' do
      expect { invoke_resubmit_script(renewal_year) }.to output("Please pass renewal year as an argument to the script. Example: renewal_year=2025 bundle exec rails runner script/application_renewals/resubmit.rb\n").to_stdout
      expect(File.exist?("#{Rails.root}/resubmit_renewal_applications_*.csv")).to be_falsey
    end
  end

  context 'failure' do
    before do
      allow(::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Resubmit).to receive(:new).and_return(operation_double)
      allow(operation_double).to receive(:call).and_return(Failure('resubmission failed'))
    end

    it 'prints a failure message' do
      expect { invoke_resubmit_script(renewal_year) }.to output("Failure: resubmission failed\n").to_stdout
    end
  end

  context 'success' do
    before do
      allow(::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::SubmitDeterminationRequest).to receive(:new).and_return(operation_double)
      allow(operation_double).to receive(:call).and_return(Success('resubmission success'))
    end

    context 'csv report' do
      before do
        invoke_resubmit_script(renewal_year)
        @csv = CSV.read(file_path, headers: true)
      end

      it 'creates a report file' do
        expect(File.exist?(file_path)).to be_truthy
      end

      it 'creates a csv file with headers' do
        expect(@csv.headers).to eq(["application_hbx_id", "original_state", "resubmission_result", "result_message"])
      end

      it 'logs all the resubmission results' do
        expect(@csv.size).to eq(2)
      end

      context 'with renewal draft application' do
        it 'logs the resubmission results in the report file' do
          expect(@csv[0]['application_hbx_id']).to eq(renewal_draft_application.hbx_id)
          expect(@csv[0]['original_state']).to eq('renewal_draft')
          expect(@csv[0]['resubmission_result']).to eq('success')
          expect(@csv[0]['result_message']).to eq('resubmission success')
        end
      end

      context 'with submitted renewal application' do
        it 'logs the resubmission results in the report file' do
          expect(@csv[1]['application_hbx_id']).to eq(submitted_application.hbx_id)
          expect(@csv[1]['original_state']).to eq('submitted')
          expect(@csv[1]['resubmission_result']).to eq('success')
          expect(@csv[1]['result_message']).to eq('resubmission success')
        end
      end
    end
  end
end

def invoke_resubmit_script(renewal_year)
  ENV['renewal_year'] = renewal_year&.to_s
  resubmit_script = File.join(Rails.root, "script/application_renewals/resubmit.rb")
  load resubmit_script
end
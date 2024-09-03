# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Resubmit, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end
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
  let(:submit_determination_request) { double }
  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
    allow(::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::SubmitDeterminationRequest).to receive(:new).and_return(submit_determination_request)
    allow(submit_determination_request).to receive(:call).and_return(Success('Successfully Published for event determination_requested'))
  end

  context 'success' do
    context 'with renewal draft application' do
      before do
        @result = subject.call({ renewal_year: renewal_year })
      end

      it 'returns array of resubmission details' do
        expect(@result.success).to be_truthy
        expect(@result.success.first[:application_hbx_id]).to eq(renewal_draft_application.hbx_id)
        expect(@result.success.first[:original_state]).to eq('renewal_draft')
        expect(@result.success.first[:resubmission_result]).to eq('success')
        expect(@result.success.first[:result_message]).to eq('Successfully Published for event determination_requested')
      end
    end

    context 'with submitted renewal application' do
      before do
        @result = subject.call({ renewal_year: renewal_year })
      end

      it 'returns array of resubmission details' do
        expect(@result.success).to be_truthy
        expect(@result.success.last[:application_hbx_id]).to eq(renewal_draft_application.hbx_id)
        expect(@result.success.last[:original_state]).to eq('submitted')
        expect(@result.success.last[:resubmission_result]).to eq('success')
        expect(@result.success.last[:result_message]).to eq('Successfully Published for event determination_requested')
      end

      it 'sets the assistance_year on the resubmitted application' do
        app = ::FinancialAssistance::Application.find(submitted_application.id)
        expect(app.assistance_year).to eq(renewal_year)
      end

      it 'sets the effective_date on the resubmitted application' do
        app = ::FinancialAssistance::Application.find(submitted_application.id)
        expect(app.effective_date).to eq(Date.new(renewal_year))
      end
    end
  end

  context 'failure' do
    context 'with no renewal eligible applications found' do
      before do
        application.set(assistance_year: current_year - 1)
        @result = subject.call({ renewal_year: renewal_year })
      end

      it 'returns a failure result' do
        expect(@result.failure?).to be_truthy
        expect(@result.failure).to eq("No renewal eligible applications found for renewal year: #{renewal_year}")
      end
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::BuildAndValidateApplicationPayload, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
    end

    context 'validating a payload in during an admin FDSH hub call' do
      let(:updated_by) { 'admin' }
      let(:update_reason) { "Requested Hub for verification" }
      let(:action) { 'request_hub' }
      let(:event) { double(success?: false, value!: double(publish: true)) }
      let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

      let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095')}
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
      let(:applicant1_has_enrolled_health_coverage) { false }
      let(:applicant1_has_eligible_health_coverage) { false }
      let(:applicant1_is_applying_coverage) { true }

      let(:applicant1_has_job_income) { false }
      let(:applicant1_has_self_employment_income) { false }
      let(:applicant1_has_unemployment_income) { false }
      let(:applicant1_has_other_income) { false }

      let(:applicant1_has_deductions) { false }

      let!(:applicant) do
        applicant = FactoryBot.create(:applicant,
                                      :with_student_information,
                                      first_name: person.first_name,
                                      last_name: person.last_name,
                                      dob: person.dob,
                                      gender: person.gender,
                                      ssn: person.ssn,
                                      application: application,
                                      ethnicity: nil,
                                      is_primary_applicant: true,
                                      person_hbx_id: person.hbx_id,
                                      is_self_attested_blind: false,
                                      is_applying_coverage: applicant1_is_applying_coverage,
                                      is_required_to_file_taxes: true,
                                      is_filing_as_head_of_household: true,
                                      is_pregnant: false,
                                      is_primary_caregiver: true,
                                      is_primary_caregiver_for: [],
                                      has_job_income: applicant1_has_job_income,
                                      has_self_employment_income: applicant1_has_self_employment_income,
                                      has_unemployment_income: applicant1_has_unemployment_income,
                                      has_other_income: applicant1_has_other_income,
                                      has_deductions: applicant1_has_deductions,
                                      is_self_attested_disabled: true,
                                      is_physically_disabled: false,
                                      citizen_status: 'us_citizen',
                                      has_enrolled_health_coverage: applicant1_has_enrolled_health_coverage,
                                      has_eligible_health_coverage: applicant1_has_eligible_health_coverage,
                                      has_eligible_medicaid_cubcare: false,
                                      is_claimed_as_tax_dependent: false,
                                      is_incarcerated: false,
                                      net_annual_income: 10_078.90,
                                      is_post_partum_period: false,
                                      is_veteran_or_active_military: true)
        applicant
      end

      let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

      let(:premiums_hash) do
        { [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}} }
      end

      let(:slcsp_info) do
        { person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}} }
      end

      let(:lcsp_info) do
        { person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}} }
      end

      let(:premiums_double) { double(:success => premiums_hash) }
      let(:slcsp_double) { double(:success => slcsp_info) }
      let(:lcsp_double) { double(:success => lcsp_info) }

      let(:fetch_double) { double(:new => double(call: premiums_double))}
      let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double))}
      let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double))}
      let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
      let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
      let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

      before do
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
        stub_const('::Operations::Products::Fetch', fetch_double)
        stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
        stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
        allow(premiums_double).to receive(:failure?).and_return(false)
        allow(slcsp_double).to receive(:failure?).and_return(false)
        allow(lcsp_double).to receive(:failure?).and_return(false)

        applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      context 'for :income request type' do
        let(:request_type) { :income }

        context 'when all validation rules pass' do
          it 'returns a Success result' do
            result = described_class.new.call(application, request_type)
            expect(result).to be_success
          end
        end

        context 'when the encrypted SSN is invalid' do
          before do
            allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
            allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
          end

          it 'returns a Failure result' do
            result = described_class.new.call(application, request_type)
            expect(result).to be_failure
          end

          it 'returns an error message' do
            result = described_class.new.call(application, request_type)
            expect(result.failure).to eq(['Invalid SSN'])
          end
        end
      end
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  include Dry::Monads[:do, :result]

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:application_id) { application.id }
  let(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      family_id: family.id,
      effective_date: TimeKeeper.date_of_record.beginning_of_year
    )
  end
  let(:applicant) do
    FactoryBot.create(
      :applicant,
      first_name: person.first_name,
      last_name: person.last_name,
      dob: person.dob,
      gender: person.gender,
      ssn: person.ssn,
      application: application,
      ethnicity: [],
      is_primary_applicant: true,
      person_hbx_id: person.hbx_id,
      is_self_attested_blind: false,
      is_applying_coverage: true,
      is_required_to_file_taxes: true,
      is_filing_as_head_of_household: true,
      is_pregnant: false,
      has_job_income: false,
      has_self_employment_income: false,
      has_unemployment_income: false,
      has_other_income: false,
      has_deductions: false,
      is_self_attested_disabled: true,
      is_physically_disabled: false,
      citizen_status: 'us_citizen',
      has_enrolled_health_coverage: false,
      has_eligible_health_coverage: false,
      has_eligible_medicaid_cubcare: false,
      is_claimed_as_tax_dependent: false,
      is_incarcerated: false,
      net_annual_income: 10_078.90,
      is_post_partum_period: false
    )
  end

  let(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

  let(:operation) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new }

  let(:update_benchmark_premiums) do
    applicant.benchmark_premiums = {
      health_only_lcsp_premiums: [{ member_identifier: applicant.person_hbx_id, monthly_premium: 90.0 }],
      health_only_slcsp_premiums: [{ member_identifier: applicant.person_hbx_id, monthly_premium: 90.0 }]
    }

    applicant.save!
  end

  before :each do
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    allow(operation).to receive(:publish).and_return(Success())
    eligibility_determination
    update_benchmark_premiums
  end

  context 'Given invalid data' do
    it 'should fail when the application does not exist' do
      invalid_id = "invalid_id"
      result = operation.call(application_id: invalid_id)
      expect(result).not_to be_success
      expect(result.failure).to eq "Unable to find Application with ID invalid_id."
    end
  end

  context 'Given a valid application' do
    before :each do
      @result = operation.call(application_id: application_id)
    end

    it 'should succeed' do
      expect(@result).to be_success
    end
  end
end

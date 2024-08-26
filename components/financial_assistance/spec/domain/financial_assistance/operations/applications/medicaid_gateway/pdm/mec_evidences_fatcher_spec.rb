# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applications::FetchLatestDeterminedApplications, dbclean: :after_each  do

  let!(:person) { FactoryBot.create(:person, hbx_id: 4_378_657_346_576) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, hbx_assigned_id: "10028") }
  let!(:application1) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      effective_date: TimeKeeper.date_of_record.beginning_of_year,
                      aasm_state: :determined)
  end
  let!(:applicant1) do
    applicant = FactoryBot.create(:applicant,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: person.ssn,
                                  application: application1,
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
                                  is_ia_eligible: true,
                                  is_post_partum_period: false)
    applicant
  end

  let!(:applicant2) do
    applicant = FactoryBot.create(:applicant,
                                  first_name: "dep1",
                                  last_name: "dep_last",
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: "493029458",
                                  application: application1,
                                  ethnicity: [],
                                  is_primary_applicant: true,
                                  person_hbx_id: 1234,
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
                                  is_ia_eligible: false,
                                  is_post_partum_period: false)
    applicant
  end

  context 'for atleast one is_ia_eligible' do
    before do
      @applicant = application1.applicants.first
      @applicant.build_esi_evidence(key: :local_mec, title: "Local MEC")
      @applicant.save!
    end

    it 'should return success' do
      result = subject.call({application_hbx_ids:  [application1.hbx_id]})
      expect(result).to be_success
    end
  end
end
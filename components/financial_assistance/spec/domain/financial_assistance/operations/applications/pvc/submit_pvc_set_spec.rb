# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Pvc::SubmitPvcSet, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
  let!(:person2) { FactoryBot.create(:person, hbx_id: "732021") }
  let!(:person3) { FactoryBot.create(:person, hbx_id: "732022") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      aasm_state: 'determined',
                      hbx_id: "830293",
                      assistance_year: TimeKeeper.date_of_record.year,
                      effective_date: TimeKeeper.date_of_record.beginning_of_year,
                      created_at: Date.new(2021, 10, 1))
  end

  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  :with_student_information,
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
                                  is_post_partum_period: false,
                                  is_ia_eligible: true)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, csr_percent_as_integer: 73) }
  let(:assistance_year) { TimeKeeper.date_of_record.year }

  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)

    allow(Family).to receive(:with_applied_aptc_or_csr_active_enrollments).and_return([family.id])
  end

  context 'success' do
    it 'should return success' do
      result = subject.call(assistance_year: assistance_year)
      expect(result).to be_success
    end
  end
end

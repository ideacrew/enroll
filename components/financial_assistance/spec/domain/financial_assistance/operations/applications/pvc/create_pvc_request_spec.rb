# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Pvc::CreatePvcRequest, dbclean: :after_each do
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
                                  encrypted_ssn: "wFDFw1whehQ1Udku1/79DA==\n")
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, csr_percent_as_integer: 73) }

  let(:premiums_hash) do
    {
      [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}},
      [person2.hbx_id] => {:health_only => {person2.hbx_id => [{:cost => 200.0, :member_identifier => person2.hbx_id, :monthly_premium => 200.0}]}},
      [person3.hbx_id] => {:health_only => {person3.hbx_id => [{:cost => 200.0, :member_identifier => person3.hbx_id, :monthly_premium => 200.0}]}}
    }
  end

  let(:slcsp_info) do
    {
      person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}},
      person2.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person2.hbx_id, :monthly_premium => 200.0}},
      person3.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person3.hbx_id, :monthly_premium => 200.0}}
    }
  end

  let(:lcsp_info) do
    {
      person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}},
      person2.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person2.hbx_id, :monthly_premium => 100.0}},
      person3.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person3.hbx_id, :monthly_premium => 100.0}}
    }
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

  let(:event) { Success(double) }
  let(:obj)  { FinancialAssistance::Operations::Applications::Pvc::CreatePvcRequest.new }

  let!(:manifest) do
    { assistance_year: TimeKeeper.date_of_record.year, type: 'pvc_manifest_type' }
  end
  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:full_medicaid_determination_step).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(FinancialAssistance::Operations::Applications::Pvc::CreatePvcRequest).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).with(anything).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
  end

  context 'success' do
    it 'should return success' do
      expect(applicant.non_esi_evidence.present?).to be_falsey
      result = subject.call(family_hbx_id: family.hbx_assigned_id, application_hbx_id: application.hbx_id, assistance_year: application.assistance_year)
      expect(result).to be_success
      expect(applicant.reload.non_esi_evidence.present?).to be_truthy
    end
  end

  it "when evidences are not created due to applicant ineligible" do
    applicant.update(is_applying_coverage: false, is_ia_eligible: false)
    expect(applicant.non_esi_evidence.present?).to be_falsey
    result = subject.call(family_hbx_id: family.hbx_assigned_id, application_hbx_id: application.hbx_id, assistance_year: application.assistance_year)
    expect(result).to be_success
    expect(applicant.reload.non_esi_evidence.present?).to be_falsey
  end

  context 'when an application fails to be transformed into an entity' do
    before do
      # validate_and_record_publish_application_errors needs to be true in order to check applicants' evidences at an individual level
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)

      application.update(aasm_state: :draft)
    end

    it 'will return a failure' do
      result = subject.call(family_hbx_id: family.hbx_assigned_id, application_hbx_id: application.hbx_id, assistance_year: application.assistance_year)
      applicant.reload
      evidence = applicant.non_esi_evidence

      expect(result).to be_failure
      expect(evidence.verification_histories.last.update_reason).to eq("PVC - Periodic verifications submission failed due to transformation failure")
      expect(evidence.aasm_state).to eq('attested')
    end
  end

  context 'when all applicants are invalid' do
    let(:service_object) { double("CheckApplicantEligibilityRules") }

    before do
      # validate_and_record_publish_application_errors needs to be true in order to check applicants' evidences at an individual level
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)

      allow(::Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules).to receive(:new).and_return(service_object)
      allow(service_object).to receive(:call).and_return(Dry::Monads::Result::Failure.new("invalid ssn"))
    end

    it 'will return a failure' do
      result = subject.call(family_hbx_id: family.hbx_assigned_id, application_hbx_id: application.hbx_id, assistance_year: application.assistance_year)
      applicant.reload
      evidence = applicant.non_esi_evidence
      error_message = "PVC - Periodic verifications submission failed due to invalid ssn"

      expect(result).to be_failure
      expect(evidence.verification_histories.last.update_reason).to eq(error_message)
      expect(evidence.aasm_state).to eq('attested')
    end
  end
end

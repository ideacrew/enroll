# frozen_string_literal: true

require 'aasm/rspec'

RSpec.describe Operations::Families::IapApplications::Rrvs::IncomeEvidences::RequestDetermination, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:person2) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:person3) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      aasm_state: 'determined',
                      hbx_id: "830293",
                      assistance_year: TimeKeeper.date_of_record.year,
                      effective_date: TimeKeeper.date_of_record.beginning_of_year,
                      created_at: Date.new(2021, 10, 1))
  end

  let(:incomes) { [FactoryBot.build(:financial_assistance_income)] }
  let(:applicant) do
    FactoryBot.create(
      :applicant,
      :with_student_information,
      first_name: person.first_name,
      last_name: person.last_name,
      dob: person.dob,
      gender: person.gender,
      ssn: "123456789",
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
      is_ia_eligible: true,
      incomes: incomes
      )
  end

  let(:applicant2) do
    FactoryBot.create(
      :applicant,
      :with_student_information,
      first_name: person2.first_name,
      last_name: person2.last_name,
      dob: person2.dob,
      gender: person2.gender,
      ssn: "856471234",
      application: application,
      ethnicity: [],
      is_primary_applicant: true,
      person_hbx_id: person2.hbx_id,
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
      is_ia_eligible: true,
      incomes: incomes
    )
  end

  let(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, csr_percent_as_integer: 73) }
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

  let(:event) { Success(double) }
  let(:obj)  { FinancialAssistance::Operations::Applications::Rrv::CreateRrvRequest.new }

  let(:benchmark_premiums) do
    {
      health_only_lcsp_premiums: [
        { member_identifier: applicant.person_hbx_id, monthly_premium: 90.0 },
        { member_identifier: applicant2.person_hbx_id, monthly_premium: 91.0 }
      ],
      health_only_slcsp_premiums: [
        { member_identifier: applicant.person_hbx_id, monthly_premium: 100.00 },
        { member_identifier: applicant2.person_hbx_id, monthly_premium: 101.00 }
      ]
    }
  end

  let(:update_benchmark_premiums) do
    benchmark_premiums
    application.applicants.each { |applicant| applicant.benchmark_premiums = benchmark_premiums }
    application.save!
  end

  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:full_medicaid_determination_step).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    allow(FinancialAssistance::Operations::Applications::Rrv::CreateRrvRequest).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    eligibility_determination
    update_benchmark_premiums
  end

  context 'success' do
    it 'should return success if assistance year is passed' do
      result = subject.call({ application_hbx_id: application.hbx_id })
      expect(result).to be_success
    end
  end

  context 'success when validate_and_record_publish_application_errors feature is enabled' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      @result = subject.call({ application_hbx_id: application.hbx_id })
      application.reload
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should record failure for valid applicant1' do
      income_evidence = application.applicants[0].income_evidence
      expect(income_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
    end

    it 'income_evidence state for valid applicant1 is pending' do
      income_evidence = application.applicants[0].income_evidence
      expect(income_evidence).to have_state(:pending)
    end

    it 'should record failure for invalid applicant' do
      income_evidence = application.applicants[1].income_evidence
      expect(income_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
    end

    it 'income_evidence for invalid applicant is pending' do
      income_evidence = application.applicants[1].income_evidence
      expect(income_evidence).to have_state(:pending)
    end
  end

  context 'when validate_and_record_publish_application_errors feature is enabled' do
    context 'when applicant is invalid' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
        application.applicants.last.unset(:encrypted_ssn)
        application.save!
        @result = subject.call({ application_hbx_id: application.hbx_id })
        application.reload
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should record failure for valid applicant1' do
        income_evidence = application.applicants[0].income_evidence
        expect(income_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'income_evidence state for valid applicant1 is negative_response_received' do
        income_evidence = application.applicants[0].income_evidence
        expect(income_evidence).to have_state(:negative_response_received)
      end

      it 'should record failure for invalid applicant' do
        income_evidence = application.applicants[1].income_evidence
        expect(income_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'income_evidence for invalid applicant is negative_response_received' do
        income_evidence = application.applicants[1].income_evidence
        expect(income_evidence).to have_state(:negative_response_received)
      end
    end

    context 'when all applicants are invalid' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
        application.applicants.each do |applicant|
          applicant.unset(:encrypted_ssn)
        end
        application.save!
        @result = subject.call({ application_hbx_id: application.hbx_id })
        application.reload
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should record failure for invalid applicant1' do
        income_evidence = application.applicants[0].income_evidence
        expect(income_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'income_evidence for invalid applicant1 is negative_response_received' do
        income_evidence = application.applicants[0].income_evidence
        expect(income_evidence).to have_state(:negative_response_received)
      end

      it 'should record failure for invalid applicant1' do
        income_evidence = application.applicants[1].income_evidence
        expect(income_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'income_evidence for invalid applicant1 is negative_response_received' do
        income_evidence = application.applicants[1].income_evidence
        expect(income_evidence).to have_state(:negative_response_received)
      end
    end
  end

  context 'without params' do
    it 'returns failure with error messages' do
      expect(subject.call({})).to eq Failure(['application hbx_id is missing'])
    end
  end
end

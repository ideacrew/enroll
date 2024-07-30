# frozen_string_literal: true

require 'aasm/rspec'

RSpec.describe Operations::Families::IapApplications::Rrvs::NonEsiEvidences::RequestDetermination, dbclean: :after_each do
  include Dry::Monads[:do, :result]

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
                                  is_ia_eligible: true)
    applicant
  end

  let!(:applicant2) do
    applicant = FactoryBot.create(:applicant,
                                  :with_student_information,
                                  first_name: person2.first_name,
                                  last_name: person2.last_name,
                                  dob: person2.dob,
                                  gender: person2.gender,
                                  ssn: nil,
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
                                  is_ia_eligible: true)
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
  let(:obj)  { FinancialAssistance::Operations::Applications::Rrv::CreateRrvRequest.new }

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
    allow(FinancialAssistance::Operations::Applications::Rrv::CreateRrvRequest).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
  end

  context 'success' do
    it 'should return success if assistance year is passed' do
      result = subject.call({ application_hbx_id: application.hbx_id })
      expect(result).to be_success
    end
  end

  context 'success
- when validate_and_record_publish_application_errors feature is enabled
- when all applicants are valid' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      applicant2.update_attributes!(ssn: "756841234")
      @result = subject.call({ application_hbx_id: application.hbx_id })
      application.reload
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should record success for valid applicant1' do
      non_esi_evidence = application.applicants[0].non_esi_evidence
      expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
    end

    it 'non_esi_evidence state for valid applicant1 is pending' do
      non_esi_evidence = application.applicants[0].non_esi_evidence
      expect(non_esi_evidence).to have_state(:pending)
    end

    it 'should record success for invalid applicant' do
      non_esi_evidence = application.applicants[1].non_esi_evidence
      expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
    end

    it 'non_esi_evidence for invalid applicant is pending' do
      non_esi_evidence = application.applicants[1].non_esi_evidence
      expect(non_esi_evidence).to have_state(:pending)
    end
  end

  context 'success
  - when validate_and_record_publish_application_errors feature is enabled
  - when all applicants are valid
  - and one of the applicant does not have non esi evidence' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      applicant2.update_attributes!(ssn: "756841234", is_applying_coverage: false, is_ia_eligible: false)
      @result = subject.call({ application_hbx_id: application.hbx_id })
      application.reload
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should record success for valid applicant1' do
      non_esi_evidence = application.applicants[0].non_esi_evidence
      expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
    end

    it 'non_esi_evidence state for valid applicant1 is pending' do
      non_esi_evidence = application.applicants[0].non_esi_evidence
      expect(non_esi_evidence).to have_state(:pending)
    end

    it 'does not have non_esi_evidence for applicant2' do
      expect(application.applicants[1].non_esi_evidence).to eq nil
    end
  end

  context 'success
  - when validate_and_record_publish_application_errors feature is enabled
  - when all applicants are valid
  - and first applicant does not have non esi evidence' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      applicant.update_attributes!(is_applying_coverage: false, is_ia_eligible: false)
      applicant2.update_attributes!(ssn: "756841234")
      @result = subject.call({application_hbx_id: application.hbx_id, family_hbx_id: family.hbx_assigned_id})
      application.reload
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should record success for valid applicant2' do
      non_esi_evidence = application.applicants[1].non_esi_evidence
      expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
    end

    it 'non_esi_evidence state for valid applicant2 is pending' do
      non_esi_evidence = application.applicants[1].non_esi_evidence
      expect(non_esi_evidence).to have_state(:pending)
    end

    it 'does not have non_esi_evidence for applicant1' do
      expect(application.applicants[0].non_esi_evidence).to eq nil
    end
  end

  context 'when validate_and_record_publish_application_errors feature is enabled' do
    context '- when applicant2 is invalid
    - and all the applicants have non_esi_evidence' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
        @result = subject.call({ application_hbx_id: application.hbx_id })
        application.reload
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should record success for valid applicant1' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
      end

      it 'non_esi_evidence for valid applicant1 is pending' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence).to have_state(:pending)
      end

      it 'should record failure for invalid applicant' do
        non_esi_evidence = application.applicants[1].non_esi_evidence
        expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'non_esi_evidence for invalid applicant is attested' do
        non_esi_evidence = application.applicants[1].non_esi_evidence
        expect(non_esi_evidence).to have_state(:attested)
      end
    end

    context '- when applicant2 is invalid
    - and applicant2 does not have non_esi_evidence' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
        applicant2.update_attributes!(is_applying_coverage: false, is_ia_eligible: false)
        @result = subject.call({ application_hbx_id: application.hbx_id })
        application.reload
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should record success for valid applicant1' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submitted'
      end

      it 'non_esi_evidence for valid applicant1 is pending' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence).to have_state(:pending)
      end

      it 'does not have non_esi_evidence for applicant2' do
        expect(application.applicants[1].non_esi_evidence).to eq nil
      end
    end

    context '- when all applicants are invalid
    - and applicants have non_esi_evidence' do
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
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'non_esi_evidence for invalid applicant1 is attested' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence).to have_state(:attested)
      end

      it 'should record failure for invalid applicant1' do
        non_esi_evidence = application.applicants[1].non_esi_evidence
        expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'non_esi_evidence for invalid applicant1 is attested' do
        non_esi_evidence = application.applicants[1].non_esi_evidence
        expect(non_esi_evidence).to have_state(:attested)
      end
    end

    context '- when all applicants are invalid
    - and applicant2 does not have non_esi_evidence' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
        application.applicants.each do |applicant|
          applicant.unset(:encrypted_ssn)
        end
        applicant2.update_attributes!(is_applying_coverage: false, is_ia_eligible: false)
        application.save!
        @result = subject.call({ application_hbx_id: application.hbx_id })
        application.reload
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should record failure for invalid applicant1' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence.verification_histories.last.action).to eq 'RRV_Submission_Failed'
      end

      it 'non_esi_evidence for invalid applicant1 is attested' do
        non_esi_evidence = application.applicants[0].non_esi_evidence
        expect(non_esi_evidence).to have_state(:attested)
      end

      it 'does not have non_esi_evidence for applicant2' do
        expect(application.applicants[1].non_esi_evidence).to eq nil
      end
    end
  end

  context 'without input params' do
    it 'returns failure with error messages' do
      expect(subject.call({})).to eq Failure(['application hbx_id is missing'])
    end
  end
end
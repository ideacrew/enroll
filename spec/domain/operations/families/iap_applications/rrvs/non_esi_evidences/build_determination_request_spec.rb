# frozen_string_literal: true

RSpec.describe Operations::Families::IapApplications::Rrvs::NonEsiEvidences::BuildDeterminationRequest, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      aasm_state: 'determined',
                      hbx_id: "830293",
                      assistance_year: TimeKeeper.date_of_record.year + 1,
                      effective_date: TimeKeeper.date_of_record.beginning_of_year,
                      created_at: Date.new(2021, 10, 1))
  end

  let!(:applicant) do
    FactoryBot.create(:applicant, :with_student_information,
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
  end


  context 'success' do
    it 'should return success if assistance year is passed' do
      result = subject.call(assistance_year: TimeKeeper.date_of_record.year + 1)
      expect(result).to be_success
    end

    it 'should return success if assistance year is not passed' do
      result = subject.call
      expect(result).to be_success
    end
  end

  context 'failure' do

    it "should fail if no applications found in the given year" do
      result = subject.call(assistance_year: TimeKeeper.date_of_record.year)
      expect(result).not_to be_success
      expect(result.failure).to eq "No determined applications with ia_eligible applicants found in assistance_year #{TimeKeeper.date_of_record.year}"
    end
  end

  context 'when family has annual redetermination' do
    let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:predecessor) do
      FactoryBot.create(:financial_assistance_application,
                        family_id: family.id,
                        aasm_state: 'determined',
                        hbx_id: "830293",
                        assistance_year: TimeKeeper.date_of_record.year,
                        effective_date: TimeKeeper.date_of_record.beginning_of_year,
                        created_at: Date.new(TimeKeeper.date_of_record.year - 1, 10, 1))
    end

    let!(:application) do
      FactoryBot.create(:financial_assistance_application,
                        family_id: family.id,
                        aasm_state: 'determined',
                        hbx_id: "830293",
                        assistance_year: TimeKeeper.date_of_record.year + 1,
                        effective_date: TimeKeeper.date_of_record.beginning_of_year,
                        predecessor_id: predecessor.id,
                        created_at: Date.new(TimeKeeper.date_of_record.year, 10, 1))
    end

    let!(:applicant) do
      FactoryBot.create(:applicant, :with_student_information,
                        first_name: person.first_name,
                        last_name: person.last_name,
                        dob: person.dob,
                        gender: person.gender,
                        ssn: person.ssn,
                        application: application,
                        ethnicity: [],
                        is_primary_applicant: true,
                        person_hbx_id: person.hbx_id,
                        is_ia_eligible: true)
    end

    context 'when new application submitted after annual redetermination' do
      let!(:new_application) do
        FactoryBot.create(:financial_assistance_application,
                          family_id: family.id,
                          aasm_state: 'determined',
                          hbx_id: "830293",
                          assistance_year: TimeKeeper.date_of_record.year + 1,
                          effective_date: TimeKeeper.date_of_record.beginning_of_year,
                          created_at: Date.new(TimeKeeper.date_of_record.year, 11, 1))
      end

      let!(:new_applicant) do
        FactoryBot.create(:applicant, :with_student_information,
                          first_name: person.first_name,
                          last_name: person.last_name,
                          dob: person.dob,
                          gender: person.gender,
                          ssn: person.ssn,
                          application: new_application,
                          ethnicity: [],
                          is_primary_applicant: true,
                          person_hbx_id: person.hbx_id,
                          is_ia_eligible: true)
      end

      let(:custom_logger) {  Logger.new("#{Rails.root}/log/rrv_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") }

      before do
        allow(Logger).to receive(:new).and_return(custom_logger)
      end

      it "should fail" do
        expect(custom_logger).to receive(:error).with(/failed to process for person with hbx_id #{person.hbx_id}/i)
        subject.call(assistance_year: TimeKeeper.date_of_record.year + 1)
      end
    end

    context 'when no application submitted after annual redetermination' do
      let(:custom_logger) {  Logger.new("#{Rails.root}/log/rrv_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") }

      before do
        allow(Logger).to receive(:new).and_return(custom_logger)
      end

      it "should process family successfully" do
        result = subject.call(assistance_year: TimeKeeper.date_of_record.year + 1)

        expect(result).to be_success
        expect(result.success).to eq "published 1 families"
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Operations::Families::TaxHouseholdGroups::CreateOnFaDetermination, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:person) { FactoryBot.create(:person)}
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
    FactoryBot.create(:applicant,
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
                      is_ia_eligible: true,
                      family_member_id: family.primary_applicant.id,
                      eligibility_determination_id: eligibility_determination.id,
                      member_determinations: member_determinations)
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, csr_percent_as_integer: 73) }
  let(:member_determinations) do
    [{
      'kind' => 'Medicaid/CHIP Determination',
      'criteria_met' => true,
      'determination_reasons' => [:not_lawfully_present_pregnant],
      'eligibility_overrides' => []
    }]
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'success' do
    before do
      @result = subject.call(application)
    end

    it 'should return success' do
      expect(@result).to be_a Dry::Monads::Result::Success
    end

    it 'should return a Tax Household Group object' do
      expect(@result.value!).to be_a TaxHouseholdGroup
    end

    it 'should create Tax Household Member object' do
      expect(@result.value!.tax_households.first.tax_household_members.first.applicant_id).to eq(family.primary_applicant.id)
    end

    it 'should create Member Determination object' do
      member_determination = @result.value!.tax_households.first.tax_household_members.first.member_determinations.first
      expect(member_determination.kind).to eq(applicant['member_determinations'].first['kind'])
      expect(member_determination.criteria_met).to eq(applicant['member_determinations'].first['criteria_met'])
      expect(member_determination.determination_reasons).to eq(applicant['member_determinations'].first['determination_reasons'])
    end
  end
end

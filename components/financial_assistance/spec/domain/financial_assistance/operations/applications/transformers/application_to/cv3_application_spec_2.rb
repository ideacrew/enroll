# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Style/ExponentialNotation
RSpec.describe ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
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
                                  is_applying_coverage: true,
                                  is_required_to_file_taxes: true,
                                  is_filing_as_head_of_household: true,
                                  is_pregnant: false,
                                  is_primary_caregiver: true,
                                  is_primary_caregiver_for: [],
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
                                  is_veteran_or_active_military: true)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

  let(:premiums_hash) do
    { [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}} }
  end

  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

  let(:premiums_hash) do
    { [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}} }
  end

  let(:slcsp_info) do
    { person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}} }
  end

  let(:lcsp_info) do
    { person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}}}
  end

  let(:premiums_double) { double(:success => premiums_hash) }
  let(:slcsp_double) { double(:success => slcsp_info) }
  let(:lcsp_double) { double(:success => lcsp_info) }

  let(:fetch_double) { double(:new => double(call: premiums_double))}
  let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double))}
  let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double))}

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
  end

  describe "#applicant_benchmark_premium slcsp/lscp values" do
    context "when there is valid address" do
      let(:result) { subject.call(application) }
      let!(:in_state_address_params) { { kind: 'home', address_1: '1 Awesome Street', address_2: '#100', city: 'Washington', state: 'DC', zip: '20001' } }
      let(:non_zero_output) do
        {:health_only_lcsp_premiums => [{:member_identifier => applicant.person_hbx_id.to_s, :monthly_premium => 0.1e3}],
         :health_only_slcsp_premiums => [{:member_identifier => applicant.person_hbx_id.to_s, :monthly_premium => 0.2e3}]}
      end

      before do
        applicant.addresses.create!(in_state_address_params)
        applicant.save!
      end

      it "should build with non zero benchmark_premium values" do
        params = result.success
        app_contract = ::AcaEntities::MagiMedicaid::Contracts::ApplicationContract.new.call(params)
        expect(result.success?).to be_truthy
        app_entity = ::AcaEntities::MagiMedicaid::Application.new(app_contract.to_h).to_h
        applicant = app_entity[:applicants][0]
        expect(applicant[:benchmark_premium]).to eq non_zero_output
      end
    end

    context "when there is invalid address" do
      let(:result) { subject.call(application) }
      let!(:out_of_state_address_params) { { kind: 'home', address_1: '1 Awesome Street', address_2: '#100', city: 'Washington', state: 'FL', zip: '12345' } }
      let(:zero_permium_output) do
        {:health_only_lcsp_premiums => [{:member_identifier => applicant.person_hbx_id.to_s, :monthly_premium => 0.0}],
         :health_only_slcsp_premiums => [{:member_identifier => applicant.person_hbx_id.to_s, :monthly_premium => 0.0}]}
      end

      before do
        applicant.addresses.create!(out_of_state_address_params)
        applicant.save!
        allow(premiums_double).to receive(:failure?).and_return(true)
        allow(slcsp_double).to receive(:failure?).and_return(true)
        allow(lcsp_double).to receive(:failure?).and_return(true)
      end

      it "should build with zero benchmark_premium values" do
        params = result.success
        app_contract = ::AcaEntities::MagiMedicaid::Contracts::ApplicationContract.new.call(params)
        expect(result.success?).to be_truthy
        app_entity = ::AcaEntities::MagiMedicaid::Application.new(app_contract.to_h).to_h
        applicant = app_entity[:applicants][0]
        expect(applicant[:benchmark_premium]).to eq zero_permium_output
      end
    end
  end
end
# rubocop:enable Style/ExponentialNotation
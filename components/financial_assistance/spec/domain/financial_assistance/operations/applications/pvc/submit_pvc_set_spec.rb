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
  let(:obj)  { FinancialAssistance::Operations::Applications::Pvc::SubmitPvcSet.new }

  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(FinancialAssistance::Operations::Applications::Pvc::SubmitPvcSet).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
  end

  context 'success' do
    it 'should return success' do
      result = subject.call(assistance_year: TimeKeeper.date_of_record.year)
      expect(result).to be_success
    end
  end

  describe "fetch_pvc_families_for_assistance_year" do
    let(:date) { TimeKeeper.date_of_record }
    let(:assistance_year) { date.year }
    let(:csr_set) { [87, 94] }

    let(:family) do
      family = FactoryBot.build(:family, person: primary)
      family.family_members = [
        FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent)
      ]

      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent.id, kind: 'spouse')
      family.save
      family
    end

    let(:dependent) { FactoryBot.create(:person) }
    let(:primary) { FactoryBot.create(:person) }
    let(:primary_applicant) { family.primary_applicant }
    let(:dependents) { family.dependents }
    let!(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: assistance_year,
        source: 'Admin',
        start_on: date.beginning_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household, effective_starting_on: date.beginning_of_year, effective_ending_on: TimeKeeper.date_of_record.end_of_year, max_aptc: 1000.00)
        ]
      )
    end

    let!(:inactive_tax_household_group) do
      family.tax_household_groups.create!(
        created_at: date - 1.months,
        assistance_year: assistance_year - 1,
        source: 'Admin',
        start_on: date.beginning_of_year - 1.year,
        end_on: date.end_of_year - 1.year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let(:tax_household) do
      tax_household_group.tax_households.first
    end

    let!(:tax_household_member) { tax_household.tax_household_members.create(applicant_id: family.family_members[0].id, csr_percent_as_integer: 87, csr_eligibility_kind: "csr_87") }

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :individual_shopping,
                        :with_silver_health_product,
                        :with_enrollment_members,
                        enrollment_members: [primary_applicant],
                        effective_on: date.beginning_of_month,
                        family: family,
                        aasm_state: :coverage_selected)
    end

    describe '#fetch_pvc_families_for_assistance_year' do
      context "when csr 87 is passed as param" do
        it 'returns families with active assisted tax households for the given year' do
          result = subject.fetch_pvc_families_for_assistance_year(assistance_year, csr_set)
          expect(result).to include(family.id)
        end
      end

      context "when csr 73 is passed as param" do
        it 'does not return other families' do
          result = subject.fetch_pvc_families_for_assistance_year(assistance_year, [73])
          expect(result).not_to include(family.id)
        end
      end

      context "when there are no active enrollments" do
        it 'does not return families' do
          hbx_enrollment.update(aasm_state: :coverage_canceled)
          result = subject.fetch_pvc_families_for_assistance_year(assistance_year, csr_set)
          expect(result).not_to include(family.id)
        end
      end

      context "when max aptc is not greater than 0" do
        it 'does not return families' do
          tax_household.update(max_aptc: 0)
          result = subject.fetch_pvc_families_for_assistance_year(assistance_year, csr_set)
          expect(result).not_to include(family.id)
        end
      end

      context "when assistance_year is previous year with inactive tax household group" do
        it 'does not return families with inactive tax households' do
          result = subject.fetch_pvc_families_for_assistance_year(assistance_year - 1, csr_set)
          expect(result).not_to include(family.id)
        end
      end
    end
  end
end

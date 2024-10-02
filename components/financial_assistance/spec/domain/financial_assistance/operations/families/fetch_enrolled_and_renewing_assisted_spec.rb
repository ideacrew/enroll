# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Families::FetchEnrolledAndRenewingAssisted do
  include Dry::Monads[:do, :result]

  let(:date) { TimeKeeper.date_of_record }
  let(:assistance_year) { date.year }
  let(:csr) { ["87", "94"] }

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
  let(:primary) {  FactoryBot.create(:person, :with_consumer_role)}
  let(:primary_applicant) { family.primary_applicant }
  let(:dependents) { family.dependents }
  let!(:tax_household_group_current) do
    family.tax_household_groups.create!(
      assistance_year: assistance_year,
      source: 'Admin',
      start_on: date.beginning_of_year,
      tax_households: [
        FactoryBot.build(:tax_household, household: family.active_household, effective_starting_on: date.beginning_of_year, effective_ending_on: TimeKeeper.date_of_record.end_of_year, max_aptc: 1000.00)
      ]
    )
  end

  let!(:tax_household_group_previous) do
    family.tax_household_groups.create!(
      assistance_year: assistance_year,
      source: 'Admin',
      start_on: date.beginning_of_year,
      tax_households: [
        FactoryBot.build(:tax_household, household: family.active_household, effective_starting_on: date.beginning_of_year - 1.year, effective_ending_on: TimeKeeper.date_of_record.end_of_year - 1.year, max_aptc: 1000.00)
      ]
    )
  end

  let!(:inactive_tax_household_group) do
    family.tax_household_groups.create!(
      created_at: date - 1.months,
      assistance_year: assistance_year,
      source: 'Admin',
      start_on: date.beginning_of_year,
      end_on: date.end_of_year,
      tax_households: [
        FactoryBot.build(:tax_household, household: family.active_household)
      ]
    )
  end

  let(:tax_household_current) do
    tax_household_group_current.tax_households.first
  end

  let(:tax_household_previous) do
    tax_household_group_previous.tax_households.first
  end

  let!(:tax_household_member) { tax_household_current.tax_household_members.create(applicant_id: family.family_members[0].id, csr_percent_as_integer: 87, csr_eligibility_kind: "csr_87") }

  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_shopping,
                      :with_silver_health_product,
                      :with_enrollment_members,
                      enrollment_members: [primary_applicant],
                      effective_on: date.beginning_of_month,
                      family: family,
                      aasm_state: :coverage_selected,
                      applied_aptc_amount: applied_aptc_amount)
  end

  let!(:silver_03) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-03', csr_variant_id: '03') }
  let!(:silver_04) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-04', csr_variant_id: '04') }

  let!(:thh_start_on) { tax_household_current.effective_starting_on }

  let(:family_member1) { family.family_members[0] }
  let(:family_member2) { family.family_members[1] }
  let!(:ivl_enr_member2)   { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member2.id, hbx_enrollment: hbx_enrollment, eligibility_date: thh_start_on) }


  context 'success' do
    let!(:applied_aptc_amount) { 100 }

    it 'should return success' do
      result = subject.call({})
      expect(result).to be_success
    end

    it 'should return the correct number of families' do
      result = subject.call({})
      expect(result.success[:families].count).to eq 1
    end
  end
end

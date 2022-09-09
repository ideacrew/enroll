# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::BuildGrant, type: :model, dbclean: :after_each do

  let(:dependent_1) { FactoryBot.create(:person, hbx_id: '1179388') }
  let(:dependent_2) { FactoryBot.create(:person, hbx_id: '1179389') }
  let(:family_relationships) do
    [
    PersonRelationship.new(relative: dependent_1, kind: "spouse"),
    PersonRelationship.new(relative: dependent_2, kind: "child")
]
  end

  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      person_relationships: family_relationships,
                      hbx_id: '1179387',
                      last_name: 'Eric',
                      first_name: 'Pierpont',
                      dob: '1984-05-22')
  end

  let(:family_members) { [person, dependent_1, dependent_2]}
  let(:family) { FactoryBot.create(:family, :with_family_members, person: person, people: family_members) }

  let(:tax_household_member_params_1) do
    {
      applicant_id: family.family_members.first.id,
      medicaid_household_size: 1,
      is_ia_eligible: is_ia_eligible_1
    }
  end

  let(:tax_household_member_params_2) do
    {
      applicant_id: family.family_members.last.id,
      medicaid_household_size: 1,
      is_ia_eligible: is_ia_eligible_2
    }
  end

  let(:tax_household_params) do
    [
      {
        eligibility_determination_hbx_id: '123454321',
        yearly_expected_contribution: Money.new(100.00),
        effective_starting_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
        max_aptc: "80.00",
        tax_household_members: [tax_household_member_params_1]
      },
      {
        eligibility_determination_hbx_id: '123454322',
        yearly_expected_contribution: Money.new(200.00),
        effective_starting_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
        max_aptc: "180.00",
        tax_household_members: [tax_household_member_params_2]
      }
    ]
  end

  let(:tax_household_group_params) do
    {
      source: 'Faa',
      application_id: '1234567',
      start_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
      end_on: nil,
      assistance_year: TimeKeeper.date_of_record.year,
      tax_households: tax_household_params
    }
  end

  before do
    th_group = family.tax_household_groups.build(tax_household_group_params)
    th_group.save!
    family.save!
  end

  context "if both the tax_households has aptc_eligible members" do
    let(:is_ia_eligible_1) { true }
    let(:is_ia_eligible_2) { true }

    it "create grants for both tax_households in the group" do
      result = subject.call(family: family, type: 'AdvancePremiumAdjustmentGrant', effective_date: TimeKeeper.date_of_record)
      expect(result.success.count).to eq 2
    end
  end

  context "if only one of the tax_households has aptc_eligible members" do
    let(:is_ia_eligible_1) { true }
    let(:is_ia_eligible_2) { false }
    it "create grants for only eligible tax_household" do
      result = subject.call(family: family, type: 'AdvancePremiumAdjustmentGrant', effective_date: TimeKeeper.date_of_record)
      expect(result.success.count).to eq 1
    end
  end
end
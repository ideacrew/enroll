# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Family, dbclean: :around_each do
  describe "#build_family_member" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:spouse) { FactoryBot.create(:person)}

    context "valid person relationship" do
      let!(:person_relationship) do
        person.person_relationships.build(relative: spouse, kind: "spouse")
        person.save
      end

      context "#build_family_member" do
        before do
          @family_member = family.build_family_member(spouse)
        end
        it "should build family member" do
          expect(@family_member).to be_a(FamilyMember)
        end

        it "should not be persisted" do
          expect(@family_member).to_not be_persisted
        end

        it "should build coverage_household member" do
          coverage_household = family.active_household.coverage_households.first
          coverage_household_member = coverage_household.coverage_household_members.where(family_member_id: @family_member.id).first
          expect(coverage_household_member.present?).to be_truthy
          expect(coverage_household_member).to_not be_persisted
        end
      end

    end

    context "invalid person relationship" do
      context "#build_family_member" do
        before do
          @family_member = family.build_family_member(spouse)
        end
        it "should build family member" do
          expect(@family_member).to be_a(FamilyMember)
        end

        it "should not be persisted" do
          expect(@family_member).to_not be_persisted
        end

        it "should build coverage_household member" do
          immediate_family_coverage_household = family.active_household.immediate_family_coverage_household
          coverage_household_member = immediate_family_coverage_household.coverage_household_members.where(family_member_id: @family_member.id).first
          expect(coverage_household_member.present?).to be_falsey
        end
      end
    end
  end

  describe 'scopes' do
    let(:date) { TimeKeeper.date_of_record }
    let(:assistance_year) { date.year }
    let(:csr) { [87, 94] }

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
          assistance_year: assistance_year,
          source: 'Admin',
          start_on: date.beginning_of_year,
          end_on: date.end_of_year,
          tax_households: [
            FactoryBot.build(:tax_household, household: family.active_household)
          ]
        )
      end

      let(:tax_household) do
        tax_household_group.tax_households.first
      end

      let!(:tax_household_member) { tax_household.tax_household_members.create(applicant_id: family.family_members[0].id, csr_percent_as_integer: 87, csr_eligibility_kind: "csr_87") }

      let(:eligibility_determination) do
        determination = family.create_eligibility_determination(effective_date: date.beginning_of_year)
        determination.grants.create(
          key: "AdvancePremiumAdjustmentGrant",
          value: yearly_expected_contribution,
          start_on: date.beginning_of_year,
          end_on: date.end_of_year,
          assistance_year: date.year,
          member_ids: family.family_members.map(&:id).map(&:to_s),
          tax_household_id: tax_household.id
        )

        determination
      end

      let(:aptc_grant) { eligibility_determination.grants.first }

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

      let(:yearly_expected_contribution) { 125.00 * 12 }


    describe '.active_assisted_tax_households_for_year' do
      it 'returns families with active assisted tax households for the given year' do
        result = Family.active_assisted_tax_households_for_year(assistance_year)
        expect(result).to include(family)
      end
    end

    describe '.with_csr' do
      it 'returns families with tax household members with the given CSR percentages' do
        result = Family.with_csr(csr)
        expect(result).to include(family)
      end
    end

    describe '.verifiable_for_year_with_csr_and_aptc' do
      it 'returns families that can be verified for the given year with the given CSR percentages and APTC' do
        result = Family.verifiable_for_year_with_csr_and_aptc(assistance_year, csr)
        expect(result).to include(family)
      end
    end
  end
end
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



    let!(:eligibility_determination_current) do
      determination = family.create_eligibility_determination(effective_date: date.beginning_of_year)
      determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: yearly_expected_contribution_current,
        start_on: date.beginning_of_year,
        end_on: date.end_of_year,
        assistance_year: date.year,
        member_ids: family.family_members.map(&:id).map(&:to_s),
        tax_household_id: tax_household_current.id
      )

      members_csr_set.each do |family_member, csr_value|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )

        state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
        state.grants.create(
          key: "CsrAdjustmentGrant",
          value: csr_value,
          start_on: TimeKeeper.date_of_record.beginning_of_year,
          end_on: TimeKeeper.date_of_record.end_of_year,
          assistance_year: TimeKeeper.date_of_record.year,
          member_ids: family.family_members.map(&:id)
        )
      end

      determination
    end

    let!(:eligibility_determination_previous) do
      determination = family.eligibility_determination
      determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: yearly_expected_contribution_previous,
        start_on: date.beginning_of_year - 1.year,
        end_on: date.end_of_year - 1.year,
        assistance_year: date.year - 1,
        member_ids: family.family_members.map(&:id).map(&:to_s),
        tax_household_id: tax_household_previous.id
      )

      members_csr_set.each do |family_member, csr_value|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )

        state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
        state.grants.create(
          key: "CsrAdjustmentGrant",
          value: csr_value,
          start_on: TimeKeeper.date_of_record.beginning_of_year - 1.year,
          end_on: TimeKeeper.date_of_record.end_of_year - 1.year,
          assistance_year: TimeKeeper.date_of_record.year - 1,
          member_ids: family.family_members.map(&:id)
        )
      end

      determination
    end

    context 'when family has aptc and same csr for all members ' do
      let(:yearly_expected_contribution_current) { 125.00 * 12 }
      let(:yearly_expected_contribution_previous) { 1000 }
      let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
      let!(:applied_aptc_amount) { 0 }

      it 'returns families with active assisted tax households for the given year' do
        result = Family.with_aptc_csr_grants_for_year(assistance_year, csr)
        expect(result).to include(family)
        expect(result.count).to eq(1)
      end
    end


    context 'family without aptc for current and same csr for all members' do
      let(:yearly_expected_contribution_current) { 0 }
      let(:yearly_expected_contribution_previous) { 1000 }
      let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
      let!(:applied_aptc_amount) { 0 }

      it 'should not return families' do
        result = Family.with_aptc_csr_grants_for_year(assistance_year, csr)
        expect(result).not_to include(family)
        expect(result.count).to eq(0)
      end
    end

    context 'family with aptc and csr_0 for all members' do
      let(:yearly_expected_contribution_current) { 1000 }
      let(:yearly_expected_contribution_previous) { 1000 }
      let(:members_csr_set) { {family_member1 => '0', family_member2 => '0'} }
      let!(:applied_aptc_amount) { 0 }

      it 'should not return families' do
        result = Family.with_aptc_csr_grants_for_year(assistance_year, csr)
        expect(result).not_to include(family)
        expect(result.count).to eq(0)
      end
    end

    context 'family without aptc for previous year and csr_87 for all members' do
      let(:yearly_expected_contribution_current) { 0 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
      let!(:applied_aptc_amount) { 0 }

      it 'should not return families' do
        result = Family.with_aptc_csr_grants_for_year(assistance_year - 1, csr)
        expect(result).not_to include(family)
        expect(result.count).to eq(0)
      end
    end

    context 'family without applied aptc or csr product' do
      let(:yearly_expected_contribution_current) { 0 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => '100', family_member2 => '100'} }
      let!(:applied_aptc_amount) { 0 }
      let(:csr_product_variant) { '03' }

      before do
        hbx_enrollment.product = silver_03
        hbx_enrollment.save!
      end

      it 'should not return families' do
        result = Family.with_applied_aptc_or_csr_active_enrollments(['04', '05'])
        expect(result).not_to include(family)
        expect(result.count).to eq(0)
      end
    end

    context 'family without csr product, but has applied aptc' do
      let(:yearly_expected_contribution_current) { 100 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => 'limited', family_member2 => 'limited'} }
      let!(:applied_aptc_amount) { 100 }
      let(:csr_product_variant) { '03' }

      before do
        hbx_enrollment.product = silver_03
        hbx_enrollment.save!
      end

      it 'should return families' do
        result = Family.with_applied_aptc_or_csr_active_enrollments(['04', '05'])
        expect(result).to include(family)
        expect(result.count).to eq(1)
      end
    end

    context 'family without applied aptc, but has csr product' do
      let(:yearly_expected_contribution_current) { 0 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => '73', family_member2 => '73'} }
      let!(:applied_aptc_amount) { 0 }
      let(:csr_product_variant) { '04' }

      before do
        hbx_enrollment.product = silver_04
        hbx_enrollment.save!
      end

      it 'should return families' do
        result = Family.with_applied_aptc_or_csr_active_enrollments(['04', '05'])
        expect(result).to include(family)
        expect(result.count).to eq(1)
      end
    end

    context 'enrolled family with aptc and csr_87 for all members' do
      let(:yearly_expected_contribution_current) { 1000 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
      let!(:applied_aptc_amount) { 0 }

      it 'returns families' do
        result = Family.with_active_coverage_and_aptc_csr_grants_for_year(assistance_year, csr)

        expect(result).to include(family)
        expect(result.count).to eq(1)
      end
    end

    context 'not enrolled family with aptc and csr_87 for all members' do
      let(:yearly_expected_contribution_current) { 1000 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
      let!(:applied_aptc_amount) { 0 }

      it 'should not return families' do
        hbx_enrollment.update(aasm_state: 'coverage_canceled')
        result = Family.with_active_coverage_and_aptc_csr_grants_for_year(assistance_year, csr)

        expect(result).not_to include(family)
        expect(result.count).to eq(0)
      end
    end

    context 'enrolled family with aptc and csr_87 for all members' do
      let(:yearly_expected_contribution_current) { 1000 }
      let(:yearly_expected_contribution_previous) { 0 }
      let(:members_csr_set) { {family_member1 => '87', family_member2 => '87'} }
      let!(:applied_aptc_amount) { 0 }

      it 'when csr is passed as array of integer values' do
        result = Family.with_active_coverage_and_aptc_csr_grants_for_year(assistance_year, [87, 94])

        expect(result).to include(family)
        expect(result.count).to eq(1)
      end
    end
  end
end
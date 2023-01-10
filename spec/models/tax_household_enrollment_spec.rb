# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHouseholdEnrollment, type: :model do
  it { is_expected.to have_attributes(group_ehb_premium: nil) }

  describe '#enrolled_aptc_members' do
    let(:start_of_month) { TimeKeeper.date_of_record.beginning_of_month }
    let(:person) { create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { create(:family, :with_primary_family_member, person: person) }
    let(:hbx_enrollment) { create(:hbx_enrollment, :individual_aptc, :with_silver_health_product, family: family, consumer_role_id: person.consumer_role.id) }
    let(:hbx_enrollment_member) do
      create(:hbx_enrollment_member,
             hbx_enrollment: hbx_enrollment,
             applicant_id: family.primary_applicant.id,
             coverage_start_on: start_of_month,
             eligibility_date: start_of_month)
    end

    let(:tax_household_group) do
      thhg = family.tax_household_groups.create!(
        assistance_year: start_of_month.year, source: 'Admin', start_on: start_of_month.year,
        tax_households: [FactoryBot.build(:tax_household, household: family.active_household)]
      )
      thhg.tax_households.first.tax_household_members.create!(
        applicant_id: family.primary_applicant.id, is_ia_eligible: is_ia_eligible
      )
      thhg
    end

    let!(:tax_household_enrollment) do
      thh_enr = TaxHouseholdEnrollment.create(
        enrollment_id: hbx_enrollment.id, tax_household_id: tax_household_group.tax_households.first.id,
        household_benchmark_ehb_premium: 500.00, available_max_aptc: 300.00
      )

      thh_enr.tax_household_members_enrollment_members.create(
        family_member_id: hbx_enrollment_member.applicant_id, hbx_enrollment_member_id: hbx_enrollment_member.id,
        tax_household_member_id: tax_household_group.tax_households.first.tax_household_members.first.id,
        age_on_effective_date: 20, relationship_with_primary: 'self', date_of_birth: start_of_month - 20.years
      )
      thh_enr
    end

    subject { tax_household_enrollment.enrolled_aptc_members }

    context 'with members eligible for APTC/CSR' do
      let(:is_ia_eligible) { true }

      it 'returns tax_household_members_enrollment_members' do
        expect(subject.present?).to be_truthy
      end
    end

    context 'without members eligible for APTC/CSR' do
      let(:is_ia_eligible) { false }

      it 'returns no tax_household_members_enrollment_members' do
        expect(subject.present?).to be_falsey
      end
    end
  end
end

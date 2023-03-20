# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Transformers::TaxHouseholdEnrollmentTo::Cv3TaxHouseholdEnrollment, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:thhg) { FactoryBot.create(:tax_household_group, family: family) }
  let!(:thh) do
    thhg.tax_households.create(
      eligibility_determination_hbx_id: '7821',
      yearly_expected_contribution: 100.00,
      effective_starting_on: TimeKeeper.date_of_record,
      max_aptc: 100.00
    )
  end
  let!(:thhm) { FactoryBot.create(:tax_household_member, applicant_id: family.primary_applicant.id, tax_household: thh, csr_eligibility_kind: "csr_limited", csr_percent_as_integer: -1) }
  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_silver_health_product,
                      :with_enrollment_members, enrollment_members: family.family_members, family: family)
  end
  let!(:hbx_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.primary_applicant.id)
  end

  let!(:thh_enrollment_member) do
    thh_enrollment.tax_household_members_enrollment_members.create(
      hbx_enrollment_member_id: hbx_enrollment_member.id,
      tax_household_member_id: thhm.id,
      age_on_effective_date: 19,
      family_member_id: family.primary_applicant.id,
      relationship_with_primary: 'self',
      date_of_birth: person.dob
    )
  end

  let(:result) { subject.call(thh_enrollment) }

  describe '#call' do
    context 'with slcsp info' do
      let(:thh_enrollment) do
        TaxHouseholdEnrollment.create(
          enrollment_id: hbx_enrollment.id,
          tax_household_id: thh.id,
          household_benchmark_ehb_premium: 100.00,
          health_product_hios_id: BSON::ObjectId.new,
          dental_product_hios_id: nil,
          household_health_benchmark_ehb_premium: 100.00,
          household_dental_benchmark_ehb_premium: 0.0,
          applied_aptc: 100.00,
          available_max_aptc: 100.00
        )
      end

      it 'should return success' do
        expect(result.success?).to be_truthy
        contract_result = AcaEntities::Contracts::PremiumCredits::TaxHouseholdEnrollmentContract.new.call(result.success)
        expect(contract_result.success?).to be_truthy
        expect(
          AcaEntities::PremiumCredits::TaxHouseholdEnrollment.new(contract_result.to_h)
        ).to be_a(AcaEntities::PremiumCredits::TaxHouseholdEnrollment)
      end
    end

    context 'without slcsp info' do
      let(:thh_enrollment) { TaxHouseholdEnrollment.create(enrollment_id: hbx_enrollment.id, tax_household_id: thh.id) }

      it 'should return success' do
        expect(result.success?).to be_truthy
        contract_result = AcaEntities::Contracts::PremiumCredits::TaxHouseholdEnrollmentContract.new.call(result.success)
        expect(contract_result.success?).to be_truthy
        expect(
          AcaEntities::PremiumCredits::TaxHouseholdEnrollment.new(contract_result.to_h)
        ).to be_a(AcaEntities::PremiumCredits::TaxHouseholdEnrollment)
      end
    end
  end
end

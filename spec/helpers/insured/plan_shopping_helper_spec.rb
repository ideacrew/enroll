# frozen_string_literal: true

require "rails_helper"

RSpec.describe Insured::PlanShoppingHelper, :type => :helper do
  let(:family)    { FactoryBot.create(:family, :with_primary_family_member) }
  let(:household) { FactoryBot.create(:household, family: family)}
  let(:tax_household) {FactoryBot.create(:tax_household, household: household)}
  let(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_shopping,
                      :with_enrollment_members,
                      enrollment_members: family.family_members,
                      family: family,
                      effective_on: TimeKeeper.date_of_record.beginning_of_year)
  end
  let(:csr_num) { '87' }
  let!(:eligibility_determination) do
    determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
    family.family_members.each do |family_member|
      subject = determination.subjects.create(
        gid: "gid://enroll/FamilyMember/#{family_member.id}",
        is_primary: family_member.is_primary_applicant,
        person_id: family_member.person.id
      )

      state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
      state.grants.create(
        key: "CsrAdjustmentGrant",
        value: csr_num,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: family.family_members.map(&:id)
      )
    end

    determination
  end

  context "display if determined and not csr 0" do

    it 'without entity' do
      expect(is_determined_and_not_csr_0?(nil, hbx_enrollment)).to eq false
    end

    it 'without enrollment' do
      expect(is_determined_and_not_csr_0?(tax_household, nil)).to eq false
    end

    context "with multi tax household" do
      before do
        EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)
      end

      context 'with valid CSR that is not 0' do
        let(:csr_num) { '87' }
        it 'should return true' do
          expect(is_determined_and_not_csr_0?(tax_household, hbx_enrollment)).to eq true
        end
      end

      context 'with valid CSR that is 0' do
        let(:csr_num) { '0' }
        it 'should return true' do
          expect(is_determined_and_not_csr_0?(tax_household, hbx_enrollment)).to eq false
        end
      end

      context 'with invalid CSR' do
        let(:csr_num) { 'FAKE' }
        it 'should return true' do
          expect(is_determined_and_not_csr_0?(tax_household, hbx_enrollment)).to eq false
        end
      end
    end

    context "without multi tax household" do
      before do
        EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(false)
      end

      it 'with valid CSR that is not 0 it should return true' do
        tax_household.tax_household_members.build(family_member: family.family_members.first, is_ia_eligible: true, csr_eligibility_kind: 'csr_87')
        expect(is_determined_and_not_csr_0?(tax_household, hbx_enrollment)).to eq true
      end

      it 'with valid CSR that is 0 it should return false' do
        tax_household.tax_household_members.build(family_member: family.family_members.first, is_ia_eligible: true, csr_eligibility_kind: 'csr_0')
        expect(is_determined_and_not_csr_0?(tax_household, hbx_enrollment)).to eq false
      end

      it 'with invalid CSR it should return false' do
        tax_household.tax_household_members.build(family_member: family.family_members.first, is_ia_eligible: true, csr_eligibility_kind: 'csr_FAKE')
        expect(is_determined_and_not_csr_0?(tax_household, hbx_enrollment)).to eq false
      end
    end
  end
end
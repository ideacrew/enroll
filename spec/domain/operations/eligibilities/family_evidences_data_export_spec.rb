# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::FamilyEvidencesDataExport,
               type: :model,
               dbclean: :after_each do
  let!(:person1) do
    FactoryBot.create(
      :person,
      :with_consumer_role,
      :with_active_consumer_role,
      first_name: 'test10',
      last_name: 'test30',
      gender: 'male'
    )
  end

  let!(:person2) do
    person =
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        first_name: 'test',
        last_name: 'test10',
        gender: 'male'
      )
    person1.ensure_relationship_with(person, 'child')
    person
  end

  let!(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: person1)
  end

  let!(:family_member) do
    FactoryBot.create(:family_member, family: family, person: person2)
  end

  let(:household) { FactoryBot.create(:household, family: family) }
  let!(:organization) do
    FactoryBot.create(:organization, legal_name: 'CareFirst', dba: 'care')
  end
  let!(:carrier_profile1) do
    FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  end
  let!(:carrier_profile2) do
    FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  end
  let!(:product1) do
    FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      benefit_market_kind: :aca_individual,
      kind: :health,
      csr_variant_id: '01'
    )
  end
  let!(:product2) do
    FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      benefit_market_kind: :aca_individual,
      kind: :dental,
      csr_variant_id: '01'
    )
  end
  let!(:hbx_enrollment1) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      enrollment_members: family.family_members,
      kind: 'individual',
      product: product1,
      household: family.latest_household,
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      enrollment_kind: 'open_enrollment',
      family: family,
      coverage_kind: 'health',
      aasm_state: 'coverage_selected',
      consumer_role: person1.consumer_role,
      enrollment_signature: true
    )
  end

  let!(:hbx_enrollment2) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      enrollment_members: family.family_members,
      kind: 'individual',
      product: product2,
      family: family,
      household: family.latest_household,
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      enrollment_kind: 'open_enrollment',
      coverage_kind: 'dental',
      aasm_state: 'coverage_selected',
      consumer_role: person1.consumer_role,
      enrollment_signature: true
    )
  end

  let(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      family_id: family.id,
      aasm_state: 'determined',
      effective_date: DateTime.now.beginning_of_month
    )
  end

  let!(:applicant1) do
    FactoryBot.build(
      :financial_assistance_applicant,
      :with_work_phone,
      :with_work_email,
      :with_home_address,
      :with_income_evidence,
      :with_esi_evidence,
      :with_non_esi_evidence,
      :with_local_mec_evidence,
      family_member_id: family.primary_applicant.id,
      application: application,
      gender: person1.gender,
      is_incarcerated: person1.is_incarcerated,
      ssn: person1.ssn,
      dob: person1.dob,
      first_name: person1.first_name,
      last_name: person1.last_name,
      is_primary_applicant: true,
      person_hbx_id: person1.hbx_id,
      is_applying_coverage: true,
      citizen_status: 'us_citizen',
      indian_tribe_member: false
    )
  end

  let!(:applicant2) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :with_work_phone,
      :with_work_email,
      :with_home_address,
      :with_ssn,
      :with_income_evidence,
      :with_esi_evidence,
      :with_non_esi_evidence,
      :with_local_mec_evidence,
      is_consumer_role: true,
      family_member_id: family_member.id,
      application: application,
      gender: person2.gender,
      is_incarcerated: person2.is_incarcerated,
      ssn: person2.ssn,
      dob: person2.dob,
      first_name: person2.first_name,
      last_name: person2.last_name,
      is_primary_applicant: false,
      person_hbx_id: person2.hbx_id,
      is_applying_coverage: true,
      citizen_status: 'us_citizen',
      indian_tribe_member: false
    )
  end

  let(:required_params) do
    { family: family, assistance_year: TimeKeeper.date_of_record.year }
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when valid attributes passed' do
    it 'should build family member data rows' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
      expect(result.success.count).to eq 2

      member_row = result.success[0]
      expect(member_row).to include(person1.hbx_id)
      expect(member_row).to include(person1.first_name)
      expect(member_row).to include(person1.last_name)

      member_row = result.success[1]
      expect(member_row).to include(person2.hbx_id)
      expect(member_row).to include(person2.first_name)
      expect(member_row).to include(person2.last_name)
    end
  end

  context 'with a deactivated family_member' do
    before { family_member.update_attributes!(is_active: false) }

    it 'includes primary and not dependent' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
      expect(result.success.count).to eq 1
      member_row = result.success[0]
      expect(member_row).to include(person1.hbx_id)
      expect(member_row).not_to include(person2.hbx_id)
    end
  end

  context 'with financial_assistance determination' do
    let!(:thhg) { FactoryBot.create(:tax_household_group, family: family) }
    let!(:new_thh) do
      thhg.tax_households.create(
        eligibility_determination_hbx_id: '7821',
        yearly_expected_contribution: 100.00,
        effective_starting_on: TimeKeeper.date_of_record,
        max_aptc: 500.00
      )
    end
    let!(:new_thhm1) { FactoryBot.create(:tax_household_member, applicant_id: family.primary_applicant.id, tax_household: new_thh, csr_percent_as_integer: 100) }
    let!(:new_thhm2) { FactoryBot.create(:tax_household_member, applicant_id: family_member.id, tax_household: new_thh, csr_percent_as_integer: 100) }

    let!(:legacy_thh) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
    let!(:legacy_thhm1) { FactoryBot.create(:tax_household_member, applicant_id: family.primary_applicant.id, tax_household: legacy_thh, csr_percent_as_integer: 73) }
    let!(:legacy_thhm2) { FactoryBot.create(:tax_household_member, applicant_id: family_member.id, tax_household: legacy_thh, csr_percent_as_integer: 73) }
    let!(:legacy_ed) { FactoryBot.create(:eligibility_determination, tax_household: legacy_thh, max_aptc: 300.00) }


    context 'when MTHHs feature is enabled' do
      before do
        EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)
      end

      it 'returns max_aptc and CSR from new THHs' do
        result = subject.call(required_params)
        expect(result.success.count).to eq 2
        member1_row = result.success[0]
        member2_row = result.success[1]
        expect(member1_row).to include(100)
        expect(member1_row).not_to include(73)
        expect(member1_row).to include(500.00)
        expect(member1_row).not_to include(300.00)
        expect(member2_row).to include(100)
        expect(member2_row).not_to include(73)
        expect(member2_row).to include(500.00)
        expect(member2_row).not_to include(300.00)
      end
    end

    context 'when MTHHs feature is disabled' do
      before do
        EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(false)
      end

      it 'returns max_aptc and CSR from legacy THHs' do
        result = subject.call(required_params)
        expect(result.success.count).to eq 2
        member1_row = result.success[0]
        member2_row = result.success[1]
        expect(member1_row).not_to include(100)
        expect(member1_row).to include(73)
        expect(member1_row).not_to include(500.00)
        expect(member1_row).to include(300.00)
        expect(member2_row).not_to include(100)
        expect(member2_row).to include(73)
        expect(member2_row).not_to include(500.00)
        expect(member2_row).to include(300.00)
      end
    end
  end
end

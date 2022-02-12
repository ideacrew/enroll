# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::FamilyDataExportProcessor,
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
    { offset: 0, limit: 100, assistance_year: TimeKeeper.date_of_record.year }
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when valid attributes passed' do
    it 'should build csv report' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
    end
  end
end


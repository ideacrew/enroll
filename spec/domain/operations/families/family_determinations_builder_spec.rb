# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Families::FamilyDeterminationsBuilder,
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

  let(:application) do
    FactoryBot.create(
      :financial_assistance_application,
      family_id: family.id,
      aasm_state: 'determined'
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
      :with_aces_evidence,
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
      :with_aces_evidence,
      is_consumer_role: true,
      family_member_id: family_member.id,
      application: application,
      gender: 'male',
      is_incarcerated: false,
      dob: TimeKeeper.date_of_record,
      first_name: 'first',
      last_name: 'last',
      is_primary_applicant: false,
      is_applying_coverage: false,
      citizen_status: 'us_citizen'
    )
  end

  before do
    EnrollRegistry[:financial_assistance]
      .feature
      .stub(:is_enabled)
      .and_return(true)
    EnrollRegistry[:validate_quadrant]
      .feature
      .stub(:is_enabled)
      .and_return(true)
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  it 'should create aptc csr determination' do
    result = subject.call(family: family)
    expect(result.success?).to be_truthy
    result.success[:subjects].each do |identifier, value|
      expect(identifier).to be_a URI
      expect(value[:determinations]).to be_present
    end
  end
end

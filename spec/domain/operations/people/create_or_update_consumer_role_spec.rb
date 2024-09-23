# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::People::CreateOrUpdateConsumerRole, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, :with_applicants, family_id: family.id) }
  let(:applicant) { application.active_applicants.last }
  let(:applicant_person) { FactoryBot.create(:person, first_name: applicant.first_name, last_name: applicant.last_name, dob: applicant.dob, ssn: applicant.ssn, gender: applicant.gender) }
  let(:applicant_family_member) do
    family_member = family.relate_new_member(applicant_person, 'child')
    family.save!
    family_member
  end
  let(:vlp_doc_params) do
    {
      vlp_subject: 'I-551 (Permanent Resident Card)',
      alien_number: "974312399",
      card_number: "7478823423442",
      expiration_date: Date.new(2020,10,31)
    }
  end
  let(:applicant_params) { applicant.attributes.merge(vlp_doc_params) }
  let(:params) { {applicant_params: applicant_params, family_member: applicant_family_member} }

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
  end

  describe 'create consumer role' do
    context 'when valid consumer role parameters passed' do

      it 'should return success with vlp document' do
        expect(applicant_person.consumer_role).to be_blank
        result = subject.call(params: params)
        expect(result.success?).to be_truthy
        expect(applicant_person.consumer_role).to be_present
        expect(applicant_person.consumer_role.citizen_status).to eq applicant.citizen_status
      end

      it 'should create demographics_group and alive_status after creating consumer role' do
        subject.call(params: params)
        demographics_group = applicant_person.demographics_group

        expect(demographics_group).to be_a DemographicsGroup
        expect(demographics_group.alive_status).to be_a AliveStatus
      end
    end
  end

  describe 'update consumer_role' do
    context 'when valid consumer role parameters with new citizen status passed' do
      let(:applicant_person) { FactoryBot.create(:person, :with_consumer_role, first_name: applicant.first_name, last_name: applicant.last_name, dob: applicant.dob, ssn: applicant.ssn, gender: applicant.gender) }

      it 'should return success with vlp document' do
        expect(applicant_person.consumer_role).to be_present
        expect(applicant_person.consumer_role.citizen_status).to eq 'us_citizen'
        result = subject.call(params: params)
        expect(result.success?).to be_truthy
        expect(applicant_person.consumer_role).to be_present
        expect(applicant_person.consumer_role.citizen_status).to eq applicant.citizen_status
      end
    end
  end
end

RSpec.describe ::Operations::People::CreateOrUpdateConsumerRole, "given:
  - an existing person
  - an existing consumer role
  - the existing consumer role has 'Y' for is applying coverage
  - the incoming application value is 'N' for applying coverage
  - optimistic_upstream_coverage_attestation_interpretation is true
", dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, :with_applicants, family_id: family.id) }
  let(:applicant) { application.active_applicants.last }
  let(:applicant_person) do
    FactoryBot.create(
      :person,
      :with_consumer_role,
      first_name: applicant.first_name,
      last_name: applicant.last_name,
      dob: applicant.dob,
      ssn: applicant.ssn,
      gender: applicant.gender
    )
  end
  let(:applicant_family_member) do
    family_member = family.relate_new_member(applicant_person, 'child')
    family.save!
    family_member
  end
  let(:vlp_doc_params) do
    {
      vlp_subject: 'I-551 (Permanent Resident Card)',
      alien_number: "974312399",
      card_number: "7478823423442",
      expiration_date: Date.new(2020,10,31)
    }
  end
  let(:applicant_params) do
    {
      is_applying_coverage: false
    }.merge(vlp_doc_params)
  end
  let(:params) do
    {
      applicant_params: applicant_params,
      family_member: applicant_family_member,
      optimistic_upstream_coverage_attestation_interpretation: true
    }
  end

  before do
    applicant_family_member
  end

  it "leaves the is_applying_coverage value as 'Y'" do
    described_class.new.call(params: params)
    applicant_person.reload
    expect(applicant_person.consumer_role.is_applying_coverage).to be_truthy
  end
end

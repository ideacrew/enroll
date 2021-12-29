# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::BuildDetermination,
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

  let(:subject_ref) { family_member.to_global_id }

  let(:eligibility_items) { [:aptc_csr_credit] }

  let(:effective_date) { Date.today }
  let(:subjects) { family.family_members.map(&:to_global_id) }

  let(:required_params) do
    { subjects: subjects, effective_date: effective_date }
  end

  before do
    [
      :financial_assistance,
      :'gid://enroll_app/Family',
      :aptc_csr_credit,
      :aca_individual_market_eligibility,
      :health_product_enrollment_status,
      :dental_product_enrollment_status
    ].each do |feature_key|
      EnrollRegistry[feature_key].feature.stub(:is_enabled).and_return(true)
    end
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when eligibility_items_requested not passed' do
    it 'should build evidences' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
    end
  end

  context 'when eligibility_items_requested passed' do
    let(:eligibility_items_requested) do
      { aptc_csr_credit: { evidence_items: [:esi_evidence] } }
    end

    let(:required_params) do
      {
        subjects: subjects,
        effective_date: effective_date,
        eligibility_items_requested: eligibility_items_requested
      }
    end

    it 'should build evidences' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
    end
  end
end

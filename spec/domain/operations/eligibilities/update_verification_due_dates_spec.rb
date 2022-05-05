# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::UpdateVerificationDueDates,
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

  let(:verification_document_due) { EnrollRegistry[:verification_document_due_in_days].item }
  let(:due_on) { TimeKeeper.date_of_record + verification_document_due.days }

  let(:required_params) do
    { family: family, assistance_year: 2022, due_on: due_on }
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let(:evidence_names) do
    %w[income_evidence esi_evidence non_esi_evidence local_mec_evidence]
  end

  let(:outstanding_types) { %w[outstanding review rejected] }
  let(:people) { [person1, person2] }
  let(:verification_type_names) do
    [
      'Social Security Number',
      'American Indian Status',
      'Citizenship',
      'Immigration status'
    ]
  end

  before do
    people.each do |person|
      person.verification_types.each{ |vt| vt.update!(validation_status: 'outstanding') }
    end
  end

  context 'when valid attributes passed' do
    before do
      application.active_applicants.each do |applicant|
        evidence_names.each do |evidence_name|
          evidence = applicant.send(evidence_name)
          applicant.set_evidence_outstanding(evidence)
        end
      end
    end

    it 'should set due on dates for applicant evidences' do
      application.reload.active_applicants.each do |applicant|
        evidence_names.each do |evidence_name|
          evidence = applicant.send(evidence_name)
          expect(evidence.outstanding?).to be_truthy
        end
      end

      result = subject.call(required_params)
      expect(result.success?).to be_truthy

      application.reload.active_applicants.each do |applicant|
        evidence_names.each do |evidence_name|
          evidence = applicant.send(evidence_name)
          expect(evidence.outstanding?).to be_truthy
          expect(evidence.due_on).to eq due_on
        end
      end
    end

    it 'should set due dates on individual verification types' do
      people.each do |person|
        person.reload
        expect(
          person
            .verification_types
            .active
            .where(:validation_status.in => outstanding_types)
            .present?
        ).to be_truthy
        person.verification_types.active.each do |verification_type|
          if verification_type_names.include?(verification_type.type_name) &&
             outstanding_types.include?(verification_type.validation_status)
            expect(verification_type.due_date).to be_blank
          end
        end
      end

      result = subject.call(required_params)
      expect(result.success?).to be_truthy

      people.each do |person|
        person.reload
        expect(
          person
            .verification_types
            .active
            .where(:validation_status.in => outstanding_types)
            .present?
        ).to be_truthy

        person.verification_types.active.each do |verification_type|
          if verification_type_names.include?(verification_type.type_name) &&
             outstanding_types.include?(verification_type.validation_status)
            expect(verification_type.due_date).to eq due_on
          end
        end
      end
    end
  end
end

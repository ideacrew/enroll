# frozen_string_literal: true

RSpec.shared_context 'eligibilities' do
  let(:application_datetime) { TimeKeeper.datetime_of_record }
  let(:application_year) { application_datetime.year }
  let(:people) { [primary_person, spouse_person, dependent_person] }
  let(:faa_applicants) do
    [primary_faa_applicant, spouse_faa_applicant, dependent_faa_applicant]
  end

  let(:rrv_ifsv_event) { EventSource::Event.new }
  let(:rrv_non_esi_evidence) { EventSource::Event.new }

  # Create and persist an FAA Application, including associated Family and
  # Person records
  def create_faa_application
    faa_application.applicants = faa_applicants
    build_faa_applicant_relationships
    faa_application.save!
    faa_application
  end

  # Create and persist a Family, including associated Person records
  def create_family
    family.save!
    family
  end

  # Create and persist three Person records including family relationships
  def create_people
    primary_person.person_relationships.build(
      relative_id: spouse_person.id,
      kind: 'spouse'
    )
    primary_person.person_relationships.build(
      relative_id: dependent_person.id,
      kind: 'child'
    )
    people.each(&:save!)
  end

  def build_faa_applicant_relationships
    faa_application.add_or_update_relationships(
      primary_faa_applicant,
      spouse_faa_applicant,
      'spouse'
    )

    faa_application.add_or_update_relationships(
      dependent_faa_applicant,
      primary_faa_applicant,
      'parent'
    )

    faa_application.add_or_update_relationships(
      dependent_faa_applicant,
      spouse_faa_applicant,
      'parent'
    )

    faa_application.build_relationship_matrix
  end

  let(:faa_application) do
    FinancialAssistance::Application.new(
      family_id: family._id,
      assistance_year: application_year.to_i,
      submitted_at: application_datetime,
      is_ridp_verified: true
    )
  end

  let(:primary_faa_applicant) do
    FinancialAssistance::Applicant.new(
      family_member_id: primary_family_member._id,
      person_hbx_id: primary_person.hbx_id,
      is_primary_applicant: true,
      is_applying_coverage: true
    )
  end
  let(:spouse_faa_applicant) do
    FinancialAssistance::Applicant.new(
      family_member_id: spouse_family_member._id,
      person_hbx_id: spouse_person.hbx_id,
      is_primary_applicant: false,
      is_applying_coverage: true
    )
  end
  let(:dependent_faa_applicant) do
    FinancialAssistance::Applicant.new(
      family_member_id: dependent_family_member._id,
      person_hbx_id: dependent_person.hbx_id,
      is_primary_applicant: false,
      is_applying_coverage: true
    )
  end

  let(:family) do
    Family.new(
      family_members: [
        primary_family_member,
        spouse_family_member,
        dependent_family_member
      ]
    )
  end
  let(:primary_family_member) do
    FamilyMember.new(
      is_primary_applicant: true,
      is_consent_applicant: true,
      person: primary_person
    )
  end
  let(:spouse_family_member) { FamilyMember.new(person: spouse_person) }
  let(:dependent_family_member) { FamilyMember.new(person: dependent_person) }

  let(:primary_person) do
    Person.new(
      first_name: primary_first_name,
      last_name: primary_last_name,
      ssn_name: primary_ssn,
      dob: primary_dob,
      address: address
    )
  end

  let(:spouse_person) do
    Person.new(
      first_name: spouse_first_name,
      last_name: spouse_last_name,
      ssn_name: spouse_ssn,
      dob: spouse_dob,
      address: address
    )
  end

  let(:dependent_person) do
    Person.new(
      first_name: dependent_first_name,
      last_name: dependent_last_name,
      ssn_name: dependent_ssn,
      dob: dependent_dob,
      address: address
    )
  end

  let(:primary_first_name) { 'Stephen' }
  let(:primary_last_name) { 'King' }
  let(:primary_ssn) { '517875959' }
  let(:primary_dob) { Date.new(1947, 9, 21) }
  let(:primary_gender) { 'male' }

  let(:spouse_first_name) { 'Tabitha' }
  let(:spouse_last_name) { 'King' }
  let(:spouse_ssn) { '516411245' }
  let(:spouse_dob) { Date.new(1949, 3, 24) }
  let(:spouse_gender) { 'female' }

  let(:dependent_first_name) { 'Naomi' }
  let(:dependent_last_name) { 'King' }
  let(:dependent_ssn) { '516411333' }
  let(:dependent_dob) { Date.new(1970, 6, 1) }
  let(:dependent_gender) { 'female' }

  let(:address) do
    {
      kind: 'home',
      address_1: '71 Melbourne St',
      city: 'Portland',
      state: 'ME',
      zip: '04101'
    }
  end

  # rubocop:disable Metrics/MethodLength
  def faa_eligibility_sample
    [
      {
        key: :aptc_financial_assistance_eligibility,
        effective_date: Date.today,
        application: application_id,
        tax_households: [
          {
            id: household_id,
            evidences: [
              income_evidence: {
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :rrv_ifsv_service,
                  value: {
                    max_aptc: 400.00,
                    csr: 94
                  },
                  event: event_id
                }
              },
              aptc_financial_assistance_evidence: {
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :ideacrew_mitc_service,
                  value: {
                    max_aptc: 400.00,
                    csr: 94
                  },
                  event: event_id
                }
              }
            ]
          }
        ],
        applicants: [
          {
            applicant: applicant_id,
            evidences: [
              {
                key: :residency_evidence,
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :self_attested,
                  value: {}
                }
              },
              {
                key: :lawful_presence_evidence,
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :fdsh_vlp_service,
                  value: {},
                  event: event_id
                }
              },
              {
                key: :immigration_evidence,
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :fdsh_xxxxxx_service,
                  value: {},
                  event: event_id
                }
              },
              {
                key: :non_incarcerated_evidence,
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :self_attested,
                  value: true,
                  event: event_id
                }
              },
              {
                key: :non_esi_evidence,
                is_satisfied: true,
                verification_outstanding: false,
                aasm_state: 'determined',
                evidence_source: {
                  key: :rrv_fdsh_medicare_service,
                  value: {},
                  event: event_id
                }
              }
            ]
          }
        ]
      }
    ]
    # snapshot.member_eligibilities
    # snapshot.unsatisfied_eligibilities
    # snapshot.satisfied_eligibilities
  end
  # rubocop:enable Metrics/MethodLength
end

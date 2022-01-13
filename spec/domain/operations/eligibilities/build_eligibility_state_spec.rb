# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::BuildEligibilityState,
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

  let(:income) do
    FactoryBot.build(:financial_assistance_income, start_on: Date.new(2020, 6, 1), end_on: nil,
                                                   amount: 2000, frequency_kind: "monthly")
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
      indian_tribe_member: false,
      incomes: [income]
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
      indian_tribe_member: false,
      incomes: [income]
    )
  end

  let(:subject_ref) { family_member.to_global_id }

  let(:eligibility_item) do
    Operations::EligibilityItems::Find
      .new
      .call(eligibility_item_key: :aptc_csr_credit)
      .success
  end

  let(:effective_date) { Date.today }
  let(:subjects) { family.family_members.map(&:to_global_id) }

  let(:required_params) do
    {
      subject: family_member.to_global_id,
      effective_date: effective_date,
      eligibility_item: eligibility_item
    }
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

  context 'when required params passed' do
    it 'should successfully build eligibility state' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
    end

    it 'should have evidence states built' do
      result = subject.call(required_params)
      eligibility_state = result.success
      expect(eligibility_state.key?(:determined_at)).to be_truthy
      expect(eligibility_state.key?(:evidence_states)).to be_truthy
      expect(eligibility_state[:evidence_states].keys).to eq eligibility_item
        .evidence_items
        .map(&:key)
        .map(&:to_sym)
    end
  end

  context '.fetch_document_status' do

    context 'fully uploaded' do
      let(:fully_uploaded_evidence_states) do
        [
          {
            income_evidence: {
              status: 'review'
            },
            esi_evidence: {
              status: 'attested'
            },
            non_esi_evidence: {
              status: 'attested'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          },
          {
            income_evidence: {
              status: 'review'
            },
            esi_evidence: {
              status: 'review'
            },
            non_esi_evidence: {
              status: 'attested'
            },
            local_mec_evidence: {
              status: 'attested'
            }
          }
        ]
      end

      context 'when all evidence states are in verified or review' do
        it 'should return fully uploaded' do
          fully_uploaded_evidence_states.each do |evidence_states|
            result = subject.send(:fetch_document_status, evidence_states)

            expect(result).to eq 'Fully Uploaded'
          end
        end
      end
    end

    context 'partially uploaded' do
      let(:partially_uploaded_evidence_states) do
        [
          {
            income_evidence: {
              status: 'outstanding'
            },
            esi_evidence: {
              status: 'review'
            },
            non_esi_evidence: {
              status: 'attested'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          },
          {
            income_evidence: {
              status: 'outstanding'
            },
            esi_evidence: {
              status: 'review'
            },
            non_esi_evidence: {
              status: 'pending'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          }
        ]
      end

      context 'when at least one evidence in outstanding and no evidences in review' do
        it 'should return partially uploaded' do
          partially_uploaded_evidence_states.each do |evidence_states|
            result = subject.send(:fetch_document_status, evidence_states)

            expect(result).to eq 'Partially Uploaded'
          end
        end
      end
    end

    context 'none uploaded' do
      let(:partially_uploaded_evidence_states) do
        [
          {
            income_evidence: {
              status: 'outstanding'
            },
            esi_evidence: {
              status: 'attested'
            },
            non_esi_evidence: {
              status: 'attested'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          },
          {
            income_evidence: {
              status: 'outstanding'
            },
            esi_evidence: {
              status: 'attested'
            },
            non_esi_evidence: {
              status: 'pending'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          }
        ]
      end

      context 'when at least one evidence in outstanding and no evidences in review status' do
        it 'should return none uploaded' do
          partially_uploaded_evidence_states.each do |evidence_states|
            result = subject.send(:fetch_document_status, evidence_states)

            expect(result).to eq 'None'
          end
        end
      end
    end

    context 'Not applicable' do
      let(:partially_uploaded_evidence_states) do
        [
          {
            income_evidence: {
              status: 'pending'
            },
            esi_evidence: {
              status: 'attested'
            },
            non_esi_evidence: {
              status: 'attested'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          },
          {
            income_evidence: {
              status: 'verified'
            },
            esi_evidence: {
              status: 'verified'
            },
            non_esi_evidence: {
              status: 'attested'
            },
            local_mec_evidence: {
              status: 'determined'
            }
          }
        ]
      end

      context 'when at least one evidence in pending and no evidences in outstanding/review' do
        it 'should return NA' do
          partially_uploaded_evidence_states.each do |evidence_states|
            result = subject.send(:fetch_document_status, evidence_states)

            expect(result).to eq 'NA'
          end
        end
      end
    end
  end
end

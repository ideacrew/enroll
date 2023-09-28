# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Transformers::PersonTo::Cv3Person, dbclean: :after_each do
  let(:is_tobacco_user) { nil }
  let(:person) { create(:person, :with_consumer_role, is_physically_disabled: nil, is_tobacco_user: is_tobacco_user) }

  describe '#transform_person_health' do

    subject { ::Operations::Transformers::PersonTo::Cv3Person.new.transform_person_health(person) }

    it 'should transform person health to hash' do
      expect(subject).to eq({ is_physically_disabled: nil })
    end

    context 'when tobacco user is present' do
      let(:is_tobacco_user) { 'N' }

      it 'should transform person health to hash' do
        expect(subject).to eq({ is_physically_disabled: nil, is_tobacco_user: 'N' })
      end
    end
  end

  describe '#construct_consumer_role' do

    subject { ::Operations::Transformers::PersonTo::Cv3Person.new.construct_consumer_role(person.consumer_role) }

    it 'should have contact method' do
      expect(subject[:contact_method]).to eq('Paper and Electronic communications')
    end

    context 'when verification_type_history_elements are present' do
      let!(:verification_type_history_element) { create(:verification_type_history_element, consumer_role: person.consumer_role) }
      subject { ::Operations::Transformers::PersonTo::Cv3Person.new.construct_consumer_role(person.consumer_role.reload) }

      it 'should construct verification_type_history_elements' do
        expect(subject[:verification_type_history_elements][0][:verification_type]).to eq(verification_type_history_element.verification_type)
      end
    end
  end

  describe '#construct_consumer_role with active and inactive vlp documents' do
    let!(:vlp_document) {person.consumer_role.vlp_documents.first}

    subject do
      person.consumer_role.update_attributes!(active_vlp_document_id: vlp_document.id)
      person.consumer_role.vlp_documents.create!(subject: "I-551 (Permanent Resident Card)")
      ::Operations::Transformers::PersonTo::Cv3Person.new.construct_consumer_role(person.consumer_role)
    end

    it 'should have one active vlp_document' do
      expect(subject[:vlp_documents].count).to eq 1
    end

    it 'retuns valid vlp document' do
      expect(subject[:vlp_documents][0][:subject]).to eq vlp_document.subject
    end
  end

  describe '#construct_consumer_role with only inactive vlp documents' do
    let!(:vlp_document) {person.consumer_role.vlp_documents.first}

    subject do
      person.consumer_role.update_attributes!(active_vlp_document_id: nil)
      ::Operations::Transformers::PersonTo::Cv3Person.new.construct_consumer_role(person.consumer_role)
    end

    it 'should not return vlp_documents' do
      expect(subject[:vlp_documents].count).to eq 0
    end
  end

  describe '#construct_consumer_role with no vlp documents' do
    subject do
      person.consumer_role.vlp_documents.destroy_all
      ::Operations::Transformers::PersonTo::Cv3Person.new.construct_consumer_role(person.consumer_role)
    end

    it 'should not return vlp_documents' do
      expect(subject[:vlp_documents].count).to eq 0
    end
  end

  describe 'consumer_role with active and inactive vlp documents should pass payload validation' do
    let!(:vlp_document) {person.consumer_role.vlp_documents.first}
    let(:consumer_role) { FactoryBot.create(:consumer_role) }
    let(:person) { FactoryBot.create(:person, consumer_role: consumer_role) }

    before do
      person.consumer_role.update_attributes!(active_vlp_document_id: vlp_document.id)
      person.consumer_role.vlp_documents.create!(subject: "I-551 (Permanent Resident Card)")
      person_payload = ::Operations::Transformers::PersonTo::Cv3Person.new.call(person).success
      person_contract = AcaEntities::Contracts::People::PersonContract.new.call(person_payload)
      person_entity = AcaEntities::People::Person.new(person_contract.to_h)
      @result = Operations::Fdsh::PayloadEligibility::CheckPersonEligibilityRules.new.call(person_entity, :dhs)
    end

    it 'should return success' do
      expect(@result).to be_success
    end
  end

  describe '#construct_person_demographics' do

    subject { ::Operations::Transformers::PersonTo::Cv3Person.new.construct_person_demographics(person) }

    context 'when is_incarcerated is nil' do
      before do
        person.update(is_incarcerated: nil)
      end

      it 'should set the value of the field to false' do
        expect(subject[:is_incarcerated]).to eq false
      end
    end
  end

  describe '#construct_resident_role' do

    let(:person) { create(:person, :with_resident_role) }

    subject { ::Operations::Transformers::PersonTo::Cv3Person.new.construct_resident_role(person.resident_role) }

    context 'when residency_determined_at field is nil' do
      it 'should not include the field in the output hash' do
        expect(subject.key?(:residency_determined_at)).to eq false
      end

      it 'should be valid according to the ResdientRole contract' do
        contract_result = ::AcaEntities::Contracts::People::ResidentRoleContract.new.call(subject)
        expect(contract_result.errors).to be_empty
      end
    end

    context 'when residency_determined_at field is not nil' do
      let!(:timestamp) { Time.now }

      before do
        person.resident_role.update(residency_determined_at: timestamp)
      end

      it 'should include the field and value in the output hash' do
        expect(subject.key?(:residency_determined_at)).to eq true
        expect(subject[:residency_determined_at]).to eq timestamp
      end

      it 'should be valid according to the ResdientRole contract' do
        contract_result = ::AcaEntities::Contracts::People::ResidentRoleContract.new.call(subject)
        expect(contract_result.errors).to be_empty
      end
    end
  end


  describe '#transform_verification_types' do

    subject { ::Operations::Transformers::PersonTo::Cv3Person.new.transform_verification_types(person.verification_types) }

    context 'due date is nil' do

      it 'should populate the due date field' do
        expect(subject.first[:due_date]).to eq person.verification_types.first.verif_due_date
      end
    end
  end

  describe '#transform_vlp_documents' do
    let(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: vlp_documents, active_vlp_document_id: vlp_document.id) }
    let(:person) { FactoryBot.create(:person, consumer_role: consumer_role) }
    let(:vlp_documents) { [vlp_document] }
    let(:vlp_document) { FactoryBot.build(:vlp_document, :other_with_i94_number) }

    context 'with vlp document of type Other (With I-94 Number)' do
      it 'returns success without raising errors' do
        person_hash = subject.call(person).success
        contract_person_hash = AcaEntities::Contracts::People::PersonContract.new.call(person_hash).to_h
        person_entity = AcaEntities::People::Person.new(contract_person_hash)
        contract_validation_result = AcaEntities::Fdsh::Vlp::H92::VlpV37Contract.new.call(
          JSON.parse(person_entity.consumer_role.vlp_documents.first.to_json).compact
        )
        expect(contract_validation_result.errors.to_h).to be_empty
      end
    end
  end
end

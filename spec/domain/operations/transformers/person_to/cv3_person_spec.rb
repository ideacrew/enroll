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
end

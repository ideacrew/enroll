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
  end
end

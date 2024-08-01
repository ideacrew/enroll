# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Crm::Family::Publish do
  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary) }

  describe '#call' do
    context 'success' do
      let(:hbx_id) { family.primary_person.hbx_id }

      it 'publishes the event successfully' do
        result = subject.call(hbx_id: hbx_id)
        expect(result.success).to eq(
          "Successfully published event: events.families.created_or_updated for family with primary person hbx_id: #{hbx_id}"
        )
      end
    end

    context 'failure' do
      context 'when a person does not exist with the given hbx_id' do
        it 'returns failure' do
          result = subject.call(hbx_id: 'primary.hbx_id')
          expect(result.failure).to eq(
            "Provide a valid person_hbx_id to fetch person. Invalid input hbx_id: primary.hbx_id"
          )
        end
      end

      context 'when person does not have primary family' do
        it 'returns failure' do
          result = subject.call(hbx_id: primary.hbx_id)
          expect(result.failure).to eq(
            "Primary Family does not exist with given hbx_id: #{primary.hbx_id}"
          )
        end
      end
    end
  end
end

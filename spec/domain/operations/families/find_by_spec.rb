# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::FindBy, dbclean: :after_each do
  subject { described_class.new.call(input_params) }

  let(:input_params) { { correlation_id: correlation_id, response: { person_hbx_id: person_hbx_id, year: year } } }

  describe '#call' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    context 'with valid input params' do
      let(:person_hbx_id) { family.primary_person.hbx_id }
      let(:year) { TimeKeeper.date_of_record.year }
      let(:correlation_id) { "12345" }

      it 'returns a success with a message' do
        expect(
          subject.success
        ).to eq('Successfully published event: events.families.found_by')
      end
    end

    context 'with invalid input params' do
      context 'invalid person hbx_id' do
        let(:person_hbx_id) { 'sdcb982c2e83' }
        let(:year) { TimeKeeper.date_of_record.year }
        let(:correlation_id) { "12345" }

        it 'returns a failure with a message' do
          expect(
            subject.failure
          ).to eq("Unable to find person with hbx_id: #{person_hbx_id}")
        end
      end

      context 'person without any family' do
        let(:person_hbx_id) { person.hbx_id }
        let(:year) { TimeKeeper.date_of_record.year }
        let(:correlation_id) { "12345" }

        it 'returns a failure with a message' do
          expect(
            subject.failure
          ).to eq("No primary family exists for person with hbx_id: #{person_hbx_id}")
        end
      end
    end
  end
end

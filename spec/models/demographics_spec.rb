# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Demographics, type: :model do
  let(:person) { FactoryBot.create(:person) }
  let(:demographics) do
    FactoryBot.create(:demographics, :with_race_and_ethnicity, demographable: person)
  end

  let(:race) { demographics.race }
  let(:ethnicity) { demographics.ethnicity }

  describe 'associations' do

    context 'parent association' do
      it 'returns correct association' do
        expect(demographics.demographable).to eq(person)
        expect(demographics.demographable).to be_a(Person)
      end
    end

    context 'child associations' do
      context 'race' do
        it 'returns correct association' do
          expect(demographics.race).to eq(race)
          expect(demographics.race).to be_a(Race)
        end
      end

      context 'ethnicity' do
        it 'returns correct association' do
          expect(demographics.ethnicity).to be_a(Ethnicity)
          expect(demographics.ethnicity).to eq(ethnicity)
        end
      end
    end
  end
end

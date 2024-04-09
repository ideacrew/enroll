# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DemographicsGroup, type: :model do
  let(:person) { FactoryBot.create(:person) }
  let(:demographics) do
    FactoryBot.create(:demographics_group, :with_race_and_ethnicity, demographable: person)
  end

  let(:race) { demographics.races.first }
  let(:ethnicity) { demographics.ethnicities.first }

  describe 'associations' do

    context 'parent association' do
      it 'returns correct association' do
        expect(demographics.demographable).to eq(person)
        expect(demographics.demographable).to be_a(Person)
      end
    end

    context 'child associations' do
      context 'races' do
        it 'returns correct association' do
          expect(demographics.races.to_a).to include(race)
          expect(demographics.races.first).to be_a(Race)
        end
      end

      context 'ethnicities' do
        it 'returns correct association' do
          expect(demographics.ethnicities.first).to be_a(Ethnicity)
          expect(demographics.ethnicities.to_a).to include(ethnicity)
        end
      end
    end
  end
end

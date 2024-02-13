# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Race, type: :model do
  let(:person) { FactoryBot.create(:person) }
  let(:demographics) do
    FactoryBot.create(:demographics, :with_race_and_ethnicity, demographable_id: person.id)
  end

  let(:race) { demographics.race }

  describe 'associations' do
    it 'returns correct association' do
      expect(race.demographics).to eq(demographics)
      expect(race.demographics).to be_a(Demographics)
    end
  end
end

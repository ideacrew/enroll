# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ethnicity, type: :model do
  let(:person) { FactoryBot.create(:person) }
  let(:demographics) do
    FactoryBot.create(:demographics, :with_race_and_ethnicity, demographable: person)
  end

  let(:ethnicity) { demographics.ethnicity }

  describe 'associations' do
    it 'returns correct association' do
      expect(ethnicity.demographics).to eq(demographics)
      expect(ethnicity.demographics).to be_a(Demographics)
    end
  end
end

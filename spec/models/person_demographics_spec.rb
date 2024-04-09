# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  let(:person) { FactoryBot.create(:person, :with_demographics_group) }

  describe 'associations' do
    it 'returns correct association' do
      expect(person.demographics_group).to be_a(DemographicsGroup)
    end
  end
end

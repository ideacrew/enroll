# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  let(:person) { FactoryBot.create(:person, :with_demographics) }

  describe 'associations' do
    it 'returns correct association' do
      expect(person.demographics.first).to be_a(Demographics)
    end
  end
end

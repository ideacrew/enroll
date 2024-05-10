# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DemographicsGroup, type: :model do
  let(:person) { FactoryBot.create(:person) }
  let(:demographics) do
    FactoryBot.create(:demographics_group, :with_alive_status, demographicable: person)
  end

  describe 'associations' do
    context 'parent association' do
      it 'returns correct association' do
        expect(demographics.demographicable).to eq(person)
        expect(demographics.demographicable).to be_a(Person)
      end
    end

    context 'child associations' do
      context 'alive_status' do
        it 'returns correct association' do
          expect(demographics.alive_status).to be_a(AliveStatus)
        end
      end
    end
  end
end

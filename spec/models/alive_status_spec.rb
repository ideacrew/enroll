# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AliveStatus, type: :model do
  let(:person) { FactoryBot.create(:person) }

  describe 'associations' do
    let(:demographics) do
      FactoryBot.create(:person_demographics_group, :with_alive_status, demographable: person)
    end

    let(:alive_status) { demographics.alive_status }

    it 'returns correct parent association' do
      expect(alive_status.person_demographics_group).to eq(demographics)
      expect(alive_status.person_demographics_group).to be_a(PersonDemographicsGroup)
    end

    it 'returns correct child association' do
      expect(alive_status.alive_evidence).to be_a(Eligibilities::Evidence)
    end
  end
end

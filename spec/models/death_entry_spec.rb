# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeathEntry, type: :model do
  let(:person) { FactoryBot.create(:person) }

  describe 'associations' do
    let(:demographics) do
      FactoryBot.create(:person_demographics_group, :with_death_entry, demographable: person)
    end

    let(:death_entry) { demographics.death_entries.first }

    it 'returns correct parent association' do
      expect(death_entry.person_demographics_group).to eq(demographics)
      expect(death_entry.person_demographics_group).to be_a(PersonDemographicsGroup)
    end

    it 'returns correct child association' do
      expect(death_entry.death_evidence).to be_a(Eligibilities::Evidence)
    end
  end

  describe 'scopes' do
    let(:demographics) { FactoryBot.create(:person_demographics_group, demographable: person) }

    let(:non_deseased_death_entry) { FactoryBot.create(:death_entry, person_demographics_group: demographics) }

    let(:deseased_death_entry) do
      FactoryBot.create(:death_entry, :deceased, person_demographics_group: demographics, created_at: non_deseased_death_entry.created_at.prev_day)
    end

    before { deseased_death_entry }

    context 'latest' do
      it 'returns the latest death_entry' do
        expect(demographics.death_entries.latest.first).to eq(non_deseased_death_entry)
      end
    end

    context 'earliest' do
      it 'returns the earliest death_entry' do
        expect(demographics.death_entries.earliest.first).to eq(deseased_death_entry)
      end
    end
  end
end

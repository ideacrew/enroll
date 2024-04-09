# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Race, type: :model do
  let(:person) { FactoryBot.create(:person) }

  describe 'associations' do
    let(:demographics) do
      FactoryBot.create(:demographics_group, :with_race_and_ethnicity, demographable: person)
    end

    let(:race) { demographics.races.first }

    it 'returns correct association' do
      expect(race.demographics_group).to eq(demographics)
      expect(race.demographics_group).to be_a(DemographicsGroup)
    end
  end

  describe 'scopes' do
    let(:demographics) { FactoryBot.create(:demographics_group, demographable: person) }

    let(:race1) { FactoryBot.create(:race, demographics_group: demographics) }
    let(:race2) { FactoryBot.create(:race, demographics_group: demographics, created_at: race1.created_at.prev_day) }

    before { race2 }

    context 'latest' do
      it 'returns the latest race' do
        expect(demographics.races.latest.first).to eq(race1)
      end
    end

    context 'earliest' do
      it 'returns the earliest race' do
        expect(demographics.races.earliest.first).to eq(race2)
      end
    end
  end

  describe '#cms_reporting_group' do
    let(:demographics) { FactoryBot.create(:demographics_group, demographable: person) }
    let(:race) { FactoryBot.create(:race, demographics_group: demographics, attested_races: attested_races) }

    context 'when attested_races' do
      shared_examples_for 'CMS Reporting Group for attested_races' do |races, reporting_group|
        let(:attested_races) { races }

        it "returns #{reporting_group} for given the given #{races}" do
          expect(race.cms_reporting_group).to eq(reporting_group)
        end
      end

      context 'for empty attested_races' do
        it_behaves_like 'CMS Reporting Group for attested_races', [], nil
      end

      context 'for race white' do
        it_behaves_like 'CMS Reporting Group for attested_races', ['white'], 'white'
      end

      context 'for race black_or_african_american' do
        it_behaves_like 'CMS Reporting Group for attested_races', ['black_or_african_american'], 'black_or_african_american'
      end

      context 'for race american_indian_or_alaskan_native' do
        it_behaves_like 'CMS Reporting Group for attested_races', ['american_indian_or_alaskan_native'], 'american_indian_or_alaskan_native'
      end

      context 'for any sub race asian' do
        it_behaves_like 'CMS Reporting Group for attested_races', ['asian_indian'], 'asian'
        it_behaves_like 'CMS Reporting Group for attested_races', ['chinese'], 'asian'
        it_behaves_like 'CMS Reporting Group for attested_races', ['filipino'], 'asian'
        it_behaves_like 'CMS Reporting Group for attested_races', ['japanese'], 'asian'
        it_behaves_like 'CMS Reporting Group for attested_races', ['korean'], 'asian'
        it_behaves_like 'CMS Reporting Group for attested_races', ['vietnamese'], 'asian'
        it_behaves_like 'CMS Reporting Group for attested_races', ['other_asian'], 'asian'
      end

      context 'for any sub race native_hawaiian_or_other_pacific_islander' do
        it_behaves_like 'CMS Reporting Group for attested_races', ['samoan'], 'native_hawaiian_or_other_pacific_islander'
        it_behaves_like 'CMS Reporting Group for attested_races', ['native_hawaiian'], 'native_hawaiian_or_other_pacific_islander'
        it_behaves_like 'CMS Reporting Group for attested_races', ['guamanian_or_chamorro'], 'native_hawaiian_or_other_pacific_islander'
        it_behaves_like 'CMS Reporting Group for attested_races', ['other_pacific_islander'], 'native_hawaiian_or_other_pacific_islander'
      end

      context 'for any unknown race' do
        it_behaves_like 'CMS Reporting Group for attested_races', ['do_not_know'], 'unknown'
        it_behaves_like 'CMS Reporting Group for attested_races', ['refused'], 'unknown'
      end

      context 'for dual races' do
        races_by_cms_group = [
          Race::RACES_FOR_CMS_GROUP_WHITE.sample,
          Race::RACES_FOR_CMS_GROUP_BLACK_OR_AFRICAN_AMERICAN.sample,
          Race::RACES_FOR_CMS_GROUP_AMERICAN_INDIAN_OR_ALASKAN_NATIVE.sample,
          Race::RACES_FOR_CMS_GROUP_ASIAN.sample,
          Race::RACES_FOR_CMS_GROUP_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER.sample
        ]

        combinations_of_dual_race = races_by_cms_group.combination(2).to_a + races_by_cms_group.combination(3).to_a + races_by_cms_group.combination(4).to_a + [races_by_cms_group]

        combinations_of_dual_race.each do |input_races|
          it_behaves_like 'CMS Reporting Group for attested_races', input_races, 'multi_racial'
        end
      end
    end
  end
end

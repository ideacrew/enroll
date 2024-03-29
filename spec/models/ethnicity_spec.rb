# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ethnicity, type: :model do
  let(:person) { FactoryBot.create(:person) }

  describe 'associations' do
    let(:demographics) do
      FactoryBot.create(:person_demographics_group, :with_race_and_ethnicity, demographable: person)
    end

    let(:ethnicity) { demographics.ethnicities.first }

    it 'returns correct association' do
      expect(ethnicity.person_demographics_group).to eq(demographics)
      expect(ethnicity.person_demographics_group).to be_a(PersonDemographicsGroup)
    end
  end

  describe 'scopes' do
    let(:demographics) { FactoryBot.create(:person_demographics_group, demographable: person) }

    let(:ethnicity1) { FactoryBot.create(:ethnicity, person_demographics_group: demographics) }
    let(:ethnicity2) { FactoryBot.create(:ethnicity, person_demographics_group: demographics, created_at: ethnicity1.created_at.prev_day) }

    before { ethnicity2 }

    context 'latest' do
      it 'returns the latest enthnicity' do
        expect(demographics.ethnicities.latest.first).to eq(ethnicity1)
      end
    end

    context 'earliest' do
      it 'returns the earliest enthnicity' do
        expect(demographics.ethnicities.earliest.first).to eq(ethnicity2)
      end
    end
  end

  describe '#cms_reporting_group' do
    let(:demographics) { FactoryBot.create(:person_demographics_group, demographable: person) }
    let(:ethnicity) { FactoryBot.create(:ethnicity, person_demographics_group: demographics, hispanic_or_latino: hispanic_or_latino) }

    context 'when hispanic_or_latino' do
      shared_examples_for 'CMS Reporting Group for hispanic_or_latino' do |input_ethnicity, reporting_group|
        let(:hispanic_or_latino) { input_ethnicity }

        it "returns #{reporting_group} for given the given #{input_ethnicity}" do
          expect(ethnicity.cms_reporting_group).to eq(reporting_group)
        end
      end

      context 'for missing hispanic_or_latino' do
        it_behaves_like 'CMS Reporting Group for hispanic_or_latino', nil, nil
      end

      context 'when yes is value for hispanic_or_latino' do
        it_behaves_like 'CMS Reporting Group for hispanic_or_latino', 'yes', 'hispanic_or_latino'
      end

      context 'when no is value for hispanic_or_latino' do
        it_behaves_like 'CMS Reporting Group for hispanic_or_latino', 'no', 'not_hispanic_or_latino'
      end

      context 'when do_not_know is value for hispanic_or_latino' do
        it_behaves_like 'CMS Reporting Group for hispanic_or_latino', 'do_not_know', 'not_hispanic_or_latino'
      end

      context 'when refused is value for hispanic_or_latino' do
        it_behaves_like 'CMS Reporting Group for hispanic_or_latino', 'refused', 'not_hispanic_or_latino'
      end
    end
  end
end

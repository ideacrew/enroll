# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxAdmin::DryRun::Individual::Benefits do
  hbx_profile) {FactoryBot.create(:hbx_profile)}
  benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, hbx_profile: hbx_profile) }
  benefit_coverage_period_previous_year = 
    FactoryBot.build(:benefit_coverage_period,
                     start_on: (TimeKeeper.date_of_record - 1.year).beginning_of_year,
                     end_on: (TimeKeeper.date_of_record - 1.year).end_of_year,
                     open_enrollment_start_on: ((TimeKeeper.date_of_record - 1.year).beginning_of_year - 2.months),
                     open_enrollment_end_on: ((TimeKeeper.date_of_record - 1.year).beginning_of_year + 1.month))

  benefit_coverage_period_this_year = 
    FactoryBot.build(:benefit_coverage_period,
                     start_on: TimeKeeper.date_of_record.beginning_of_year,
                     end_on: TimeKeeper.date_of_record.end_of_year,
                     open_enrollment_start_on: (TimeKeeper.date_of_record.beginning_of_year - 2.months),
                     open_enrollment_end_on: (TimeKeeper.date_of_record.beginning_of_year + 1.month))

  benefit_coverage_period_next_year = 
    FactoryBot.build(:benefit_coverage_period,
                     start_on: (TimeKeeper.date_of_record + 1.year).beginning_of_year,
                     end_on: (TimeKeeper.date_of_record + 1.year).end_of_year,
                     open_enrollment_start_on: ((TimeKeeper.date_of_record + 1.year).beginning_of_year - 2.months),
                     open_enrollment_end_on: ((TimeKeeper.date_of_record + 1.year).beginning_of_year + 1.month))

  before do
    benefit_sponsorship.benefit_coverage_periods << [benefit_coverage_period_previous_year, benefit_coverage_period_this_year, benefit_coverage_period_next_year]
  end

  context 'with valid data' do
    it 'should return renewal benefit coverage params' do
      result = described_class.new.call
      expect(result).to be_success
    end
  end
end
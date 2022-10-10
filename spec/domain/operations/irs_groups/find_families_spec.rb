# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::IrsGroups::FindFamilies, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }

  describe 'Invalid Params' do
    it "failes with invalid enrollment " do
      result = described_class.new.call({start_date: nil, end_date: nil})
      expect(result.success?).to be_falsey
    end
  end

  describe 'Invalid Params' do
    it "failes with invalid enrollment " do
      result = described_class.new.call({start_date: family.created_at, end_date: family.created_at})
      expect(result.success?).to be_falsey
    end
  end

  describe 'no families in given date range' do
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :family => family,
                        :aasm_state => "coverage_enrolled",
                        :coverage_kind => "dental",
                        :effective_on => TimeKeeper.date_of_record.beginning_of_month)
    end

    it "failes without any families" do
      start_date = TimeKeeper.date_of_record.next_month.beginning_of_month
      result = described_class.new.call({start_date: start_date, end_date: start_date + 1.year})
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("No enrolled Families by health in given date range")
    end

    it "no health_coverage for the given family" do
      start_date = TimeKeeper.date_of_record.beginning_of_year
      result = described_class.new.call({start_date: start_date, end_date: start_date + 1.year})

      expect(result.success?).to be_falsey
      expect(result.failure).to eq("No enrolled Families by health in given date range")
    end
  end

  describe 'with valid params' do
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :family => family,
                        :aasm_state => "coverage_enrolled",
                        :coverage_kind => "health",
                        :effective_on => TimeKeeper.date_of_record.beginning_of_month)
    end

    it "success with correct family" do
      start_date = TimeKeeper.date_of_record.beginning_of_year

      result = described_class.new.call({start_date: start_date, end_date: start_date + 1.year})
      expect(result.success?).to be_truthy
    end
  end
end

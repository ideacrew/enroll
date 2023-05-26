# frozen_string_literal: true

require "rails_helper"

# referred spec examples from self_service_factory_spec.rb
RSpec.describe ::HbxEnrollments::CalculateEffectiveOnForEnrollment, :dbclean => :after_each do
  let!(:current_year) { Date.today.year }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:current_year) { Date.today.year }

# prospective year enrollment effective_on date
  context "within OE before last month's IndividualEnrollmentDueDayOfMonth" do
    before do
      system_date = rand(Date.new(current_year, 11, 1)..Date.new(current_year, 12, 1))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.next_year.year, 2, 1))
    end

    it 'should return start of next year as effective date' do
      expect(@context.new_effective_on.to_date).to eq(Date.today.next_year.beginning_of_year)
    end
  end

  context "within OE before last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
    before do
      system_date = rand(Date.new(current_year, 12, 1)..Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.next_year.year, 1, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 1, 1))
    end
  end

  context "within OE before last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with effective date 2/1" do
    before do
      system_date = rand(Date.new(current_year, 12, 1)..Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.next_year.year, 2, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 1, 1))
    end
  end

  context "within OE before last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
    before do
      system_date = rand(Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year, 12, 31))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.next_year.year, 1, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 2, 1))
    end
  end

  context "within OE before last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth and has a 2/1 effective_date" do
    before do
      system_date = rand(Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year, 12, 31))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.next_year.year, 2, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 2, 1))
    end
  end

  context "within OE before last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth and has a 3/1 effective_date" do # for scenarios when there is any bad data and we try to re-shop
    before do
      system_date = rand(Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year, 12, 31))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.next_year.year, 3, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 2, 1))
    end
  end

  context "within OE last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
    before do
      system_date = rand(Date.new(current_year.next, 1, 1)..Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.year, 1, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 2, 1))
    end
  end

  context "within OE last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with effective date 2/1" do
    before do
      system_date = rand(Date.new(current_year.next, 1, 1)..Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.year, 2, 1))
    end

    it 'should return start of as 2/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 2, 1))
    end
  end

  context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
    before do
      system_date = rand(Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year.next, 1, 31))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.year, 2, 1))
    end

    it 'should return start of as 3/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 3, 1))
    end
  end

  context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth effective date 3/1" do
    before do
      system_date = rand(Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year.next, 1, 31))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.year, 3, 1))
    end

    it 'should return start of as 3/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 3, 1))
    end
  end

  context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth effective date 1/1 and 15 day disabled" do
    before do
      EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature.stub(:is_enabled).and_return(true)
      system_date = Date.new(Date.today.year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(Date.today.year.next, 1, 1))
    end

    it 'should return start of as 1/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 1, 1))
    end
  end

  context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth effective date 3/1 with override" do
    before do
      EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature.stub(:is_enabled).and_return(true)
      system_date = rand(Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year.next, 1, 31))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.year, 3, 1))
    end

    it 'should return start of as 3/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year.next, 2, 1))
    end
  end

  context "outside OE after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with override enabled" do
    before do
      EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature.stub(:is_enabled).and_return(true)
      system_date = Date.new(current_year, 2, Settings.aca.individual_market.monthly_enrollment_due_on.next)
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: system_date)
    end

    it 'should return start of as 3/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year, 3, 1))
    end
  end

  context "outside OE on monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with override enabled" do
    before do
      EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature.stub(:is_enabled).and_return(true)
      system_date = Date.new(current_year, 1, Settings.aca.individual_market.monthly_enrollment_due_on)
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      @context = described_class.call(system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'),base_enrollment_effective_on: Date.new(system_date.year, 1, 31))
    end

    it 'should return start of as 3/1' do
      expect(@context.new_effective_on.to_date).to eq(Date.new(Date.today.year, 2, 1))
    end
  end
end

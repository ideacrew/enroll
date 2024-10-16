require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationSchedular, type: :model, :dbclean => :after_each do
    subject {::BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new}

    describe "#map_binder_payment_due_date_by_start_on" do
      let(:benefit_application_schedular) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new }
      let(:date_hash) do
        {
          "2024-02-01" => "2024,1,12",
          "2024-03-01" => "2024,2,12",
          "2024-04-01" => "2024,3,12",
          "2024-05-01" => "2024,4,12",
          "2024-06-01" => "2024,5,13",
          "2024-11-01" => "2024,10,15",
          "2026-07-01" => "2026,6,12",
          "2018-11-01" => "2018,10,12"
        }
      end

      context 'when start on in hash key' do
        it 'should return the corresponding value' do
          date_hash.each do |pair|
            expect(benefit_application_schedular.map_binder_payment_due_date_by_start_on(false, Date.parse(pair.first.to_s))).to eq(Date.strptime(pair.last, '%Y,%m,%d'))
          end
        end
      end
    end

    describe 'start_on_options_with_schedule' do
      let(:dates_hash) { subject.start_on_options_with_schedule(false, true) }
      let(:first_oe_date) { dates_hash.values.first[:open_enrollment_start_on] }

      it 'should return a instance of Hash' do
        expect(dates_hash).to be_a Hash
      end

      it 'should have sub keys' do
        [:open_enrollment_start_on, :open_enrollment_end_on].each do |dt_key|
          expect(dates_hash.values.first.has_key?(dt_key)).to be_truthy
        end
      end

      if (TimeKeeper.date_of_record).future?
        it "should return today's date for start_on" do
          expect(first_oe_date).to eq TimeKeeper.date_of_record
        end
      end

      context "if the TimeKeeper's day is after monthly_end_on" do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(2019, 1, 29))
        end

        it 'should return hash with 2 date keys' do
          ba_schedular = subject.start_on_options_with_schedule(false, true)
          [Date.new(2019, 2, 1), Date.new(2019, 3, 1)].each do |date|
            expect(ba_schedular.keys.include?(date)).to be_truthy
          end
        end

        it 'should return hash with dates based on exchange' do
          ba_schedular = subject.start_on_options_with_schedule(false, false)
          if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
            expect(ba_schedular.keys).to eq [Date.new(2019, 3, 1)]
          else
            expect(ba_schedular.keys).to eq [Date.new(2019, 3, 1), Date.new(2019, 4, 1)]
          end
        end
      end
    end

    describe 'calculate_start_on_dates' do
      let(:previous_date) { Date.new(2019, 1, 2) }
      let(:later_date) { Date.new(2019, 1, 28) }
      let(:both_dates) { [Date.new(2019, 2, 1), Date.new(2019, 3, 1)] }
      let(:dc_dates) { [Date.new(2019, 2, 1), Date.new(2019, 3, 1), Date.new(2019, 4, 1)] }
      let(:dc_dates_with_late_rates) { [Date.new(2019, 2, 1), Date.new(2019, 3, 1)] }
      let(:dates) do
        if previous_date.day > Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month
          dc_dates
        else
          dc_dates_with_late_rates
        end
      end

      context 'after open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(later_date)
        end

        context 'not an admin data table action' do
          it 'should return dates based on exchange' do
            if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
              expect(subject.calculate_start_on_dates).to eq [Date.new(2019, 3, 1)]
            else
              expect(subject.calculate_start_on_dates).to eq [Date.new(2019, 3, 1), Date.new(2019, 4, 1)]
            end
          end
        end

        context 'not an admin data table action' do
          it 'should return dates based on exchange' do
            if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
              expect(subject.calculate_start_on_dates(true)).to eq both_dates
            else
              expect(subject.calculate_start_on_dates(true)).to eq dc_dates
            end
          end
        end
      end

      context 'before open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(previous_date)
        end

        context 'not an admin data table action' do
          it 'should return dates based on exchange' do
            if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
              expect(subject.calculate_start_on_dates).to eq both_dates
            else
              expect(subject.calculate_start_on_dates).to eq dates
            end
          end
        end

        context 'not an admin data table action' do
          it 'should return correct dates based on exchange' do
            if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
              expect(subject.calculate_start_on_dates(true)).to eq both_dates
            else
              expect(subject.calculate_start_on_dates(true)).to eq dates
            end
          end
        end
      end
    end

    describe 'open_enrollment_period_by_effective_date' do
      let(:start_on) { Date.new(2019, 2, 1) }
      let(:previous_date) { Date.new(2019, 1, 2) }
      let(:later_date) { Date.new(2019, 1, 28) }
      let(:default_monthly_end_on_date) { Date.new(2019, 1, Settings.aca.shop_market.open_enrollment.monthly_end_on) }
      let(:oe_min_days) { Settings.aca.shop_market.open_enrollment.minimum_length.days }
      let(:oe_start_date) { (start_on - Settings.aca.shop_market.open_enrollment.maximum_length.months.months) }

      context 'after open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(later_date)
        end

        context 'not an admin data table action' do
          it 'should return 1 date' do
            expect(subject.open_enrollment_period_by_effective_date(false, start_on, false)).to eq (oe_start_date..default_monthly_end_on_date)
          end
        end

        context 'not an admin data table action' do
          it 'should return 2 dates' do
            expect(subject.open_enrollment_period_by_effective_date(false, start_on, true)).to eq (oe_start_date..default_monthly_end_on_date)
          end
        end
      end

      context 'before open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(previous_date)
        end

        context 'not an admin data table action' do
          it 'should return 1 date' do
            expect(subject.open_enrollment_period_by_effective_date(false, start_on, false)).to eq (oe_start_date..default_monthly_end_on_date)
          end
        end

        context 'not an admin data table action' do
          it 'should return 2 dates' do
            expect(subject.open_enrollment_period_by_effective_date(false, start_on, true)).to eq (oe_start_date..default_monthly_end_on_date)
          end
        end
      end
    end

    describe 'business_day?' do
      context 'given a business day' do
        it 'should return true' do
          date = Date.new(2024,1,22)
          expect(subject.business_day?(date)).to eq true
        end
      end

      context 'given a holiday' do
        it 'should return false' do
          date = Date.new(2023,6,19) # Juneteenth 2023
          expect(subject.business_day?(date)).to eq false
        end
      end

      context 'given an observed holiday' do
        it 'should return false' do
          date = Date.new(2023,11,10) # Veteran's Day - Saturday 2023, observed on Friday
          expect(subject.business_day?(date)).to eq false
        end
      end
    end
  end
end

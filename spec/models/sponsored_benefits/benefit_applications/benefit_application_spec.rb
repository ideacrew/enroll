require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::BenefitApplication, type: :model, dbclean: :around_each do
    let(:subject) { BenefitApplications::BenefitApplication.new }

    # let(:date_range) { (Date.today..1.year.from_now) }

    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

  # field :recorded_sic_code, type: String
  # field :recorded_rating_area, type: String


    let(:params) do
      {
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period,
      }
    end


    context "with no arguments" do
      subject { described_class.new }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with no effective_period" do
      subject { described_class.new(params.except(:effective_period)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with no open enrollment period" do
      subject { described_class.new(params.except(:open_enrollment_period)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with all required arguments" do
      subject { described_class.new(params) }

      it "should be valid" do
        subject.validate
        expect(subject).to be_valid
      end
    end

    context "a BenefitApplication class" do
      let(:subject)             { BenefitApplications::BenefitApplication }
      let(:standard_begin_day)  { 10 }
      let(:grace_begin_day)     { 15 }

      it "should return the day of month deadline for an open enrollment standard period to begin" do
        expect(subject.open_enrollment_begin_deadline_day_of_month).to eq standard_begin_day
      end

      it "should return the day of month deadline for an open enrollment grace period to begin" do
        expect(subject.open_enrollment_begin_deadline_day_of_month(true)).to eq grace_begin_day
      end

      context "and passed a calendar date" do
        let(:seed_date)                         { Date.new(2018,4,4) }
        let(:next_month)                        { seed_date.beginning_of_month + 1.month }
        let(:following_month)                   { seed_date.beginning_of_month + 2.months }

        let(:standard_period_last_day)          { subject.open_enrollment_begin_deadline_day_of_month }
        let(:standard_period_deadline_date)     { Date.new(seed_date.year, seed_date.month, standard_period_last_day) }
        let(:standard_period_pre_deadline_date) { standard_period_deadline_date - 1.day }

        let(:grace_period_last_day)             { subject.open_enrollment_begin_deadline_day_of_month(true) }
        let(:grace_period_deadline_date)        { Date.new(seed_date.year, seed_date.month, grace_period_last_day) }
        let(:grace_period_post_deadline_date)   { grace_period_deadline_date + 1.day }


        context "that is before standard period deadline" do
          it "should provide an effective (standard) period begin date for the first of next month" do
            expect(subject.effective_period_begin_on_by_date(standard_period_pre_deadline_date)).to eq next_month
          end

          it "should provide an effective (grace) period begin date for the first of next month" do
            expect(subject.effective_period_begin_on_by_date(standard_period_pre_deadline_date, true)).to eq next_month
          end
        end

        context "that is the same day as the standard period deadline" do
          it "should provide an effective (standard) period begin date for the first of next month" do
            expect(subject.effective_period_begin_on_by_date(standard_period_deadline_date)).to eq next_month
          end

          it "should provide an effective (grace) period begin date for the first of next month" do
            expect(subject.effective_period_begin_on_by_date(standard_period_deadline_date, true)).to eq next_month
          end
        end

        context "that is after the standard period, but before the grace period deadline" do
          it "should provide an effective (standard) period begin date for the first of month following next month" do
            expect(subject.effective_period_begin_on_by_date(grace_period_deadline_date)).to eq following_month
          end

          it "should provide an effective (grace) period begin date for the of first next month" do
            expect(subject.effective_period_begin_on_by_date(grace_period_deadline_date, true)).to eq next_month
          end
        end

        context "that is after both the standard and grace period deadlines" do
          it "should provide an effective (standard) period begin date for the first of month following next month" do
            expect(subject.effective_period_begin_on_by_date(grace_period_post_deadline_date)).to eq following_month
          end

          it "should provide an effective (grace) period begin date for the first of month following next month" do
            expect(subject.effective_period_begin_on_by_date(grace_period_post_deadline_date, true)).to eq following_month
          end

        end

      end
    end


    # it "assigns date ranges correctly" do
    #   expect(subject.send(:tidy_date_range, date_range)).to be_kind_of(Range)
    # end

    # it "assigns effective_period correctly" do
    #   subject.effective_period = date_range
    #   expect(subject.effective_period).to eq(date_range)
    # end
  end
end

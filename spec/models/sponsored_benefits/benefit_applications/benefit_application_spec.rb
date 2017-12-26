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




    # it "assigns date ranges correctly" do
    #   expect(subject.send(:tidy_date_range, date_range)).to be_kind_of(Range)
    # end

    # it "assigns effective_period correctly" do
    #   subject.effective_period = date_range
    #   expect(subject.effective_period).to eq(date_range)
    # end
  end
end

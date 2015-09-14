require 'rails_helper'

RSpec.describe BenefitSponsorship, :type => :model do

  subject { BenefitSponsorship.new }
  
  context '.is_under_open_enrollment?' do
    context 'when under open enrollment' do 
      let(:benefit_coverage_period) { FactoryGirl.build(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record - 10.days, open_enrollment_end_on: TimeKeeper.date_of_record + 10.days) }

      before do
        allow(subject).to receive(:benefit_coverage_periods).and_return([benefit_coverage_period])
      end

      it 'should return true' do 
        expect(subject.is_under_open_enrollment?).to be_truthy
      end
    end

    context 'when not under open enrollment' do
      let(:benefit_coverage_period) { FactoryGirl.build(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record + 10.days, open_enrollment_end_on: TimeKeeper.date_of_record + 40.days) }

      before do
        allow(subject).to receive(:benefit_coverage_periods).and_return([benefit_coverage_period])
      end

      it 'should return false' do 
        expect(subject.is_under_open_enrollment?).to be_falsey
      end
    end
  end

  context '.current_benefit_coverage_period' do
    let(:benefit_coverage_period1) { FactoryGirl.build(:benefit_coverage_period, start_on: (TimeKeeper.date_of_record + 1.year).beginning_of_year, end_on: (TimeKeeper.date_of_record + 1.year).end_of_year) }
    let(:benefit_coverage_period2) { FactoryGirl.build(:benefit_coverage_period, start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: TimeKeeper.date_of_record.end_of_year) }

    before do
      allow(subject).to receive(:benefit_coverage_periods).and_return([benefit_coverage_period1, benefit_coverage_period2])
    end

    context 'when current benefit coverage period exists' do 
      it 'should return current benefit coverage period' do 
        expect(subject.current_benefit_coverage_period).to eq(benefit_coverage_period2)
      end
    end

    context 'when current benefit coverage period not exists' do
      let(:benefit_coverage_period2) { FactoryGirl.build(:benefit_coverage_period, start_on: (TimeKeeper.date_of_record - 1.year).beginning_of_year, end_on: (TimeKeeper.date_of_record - 1.year).end_of_year) }

      it 'should return current benefit coverage period' do 
        expect(subject.current_benefit_coverage_period).to be_nil
      end
    end
  end

  pending "add some examples to (or delete) #{__FILE__}"
end

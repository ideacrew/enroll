require 'rails_helper'

RSpec.describe BenefitSponsorship, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"

  let!(:benefit_coverage_period) { FactoryGirl.create(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record - 10.days, open_enrollment_end_on: TimeKeeper.date_of_record + 10.days) }
  
  context '.is_under_open_enrollment?' do

    context 'when under open enrollment' do 
      it 'should return true' do 
        benefit_sponsorship = benefit_coverage_period.benefit_sponsorship
        expect(benefit_sponsorship.is_under_open_enrollment?).to be_truthy
      end
    end

    context 'when not under open enrollment' do
      let!(:benefit_coverage_period) { FactoryGirl.create(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record - 20.days, open_enrollment_end_on: TimeKeeper.date_of_record - 10.days) }

      it 'should return false' do 
        benefit_sponsorship = benefit_coverage_period.benefit_sponsorship
        expect(benefit_sponsorship.is_under_open_enrollment?).to be_falsey
      end
    end
  end

  context '.earliest_effective_date' do

    context 'when under open enrollment' do 
      it 'should return earliest effective date' do
        benefit_sponsorship = benefit_coverage_period.benefit_sponsorship
        expect(benefit_sponsorship.earliest_effective_date).to eq(benefit_coverage_period.earliest_effective_date)
      end
    end

    context 'when not under open enrollment' do
      let!(:benefit_coverage_period) { FactoryGirl.create(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record - 20.days, open_enrollment_end_on: TimeKeeper.date_of_record - 10.days) }

      it 'should return nil' do 
        benefit_sponsorship = benefit_coverage_period.benefit_sponsorship
        expect(benefit_sponsorship.earliest_effective_date).to be_nil
      end
    end
  end
end

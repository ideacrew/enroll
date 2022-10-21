# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::EnrollmentDates::EarliestEffectiveDate do

  let(:assistance_year) { TimeKeeper.date_of_record.year }
  let(:result) { subject.call(application_date: application_date, assistance_year: assistance_year) }

  describe 'Earliest Effective Date Operation' do
    context 'without assistance_year_based_effective_date enabled' do
      context 'when passed date outside open enrollment' do
        context 'and before enrollment monthly due date' do
          let(:application_date) { Date.new(Date.today.year, 5, 5)}


          it 'should return next month begin as effective date' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq application_date.next_month.beginning_of_month
          end
        end

        context 'and after enrollment monthly due date' do
          let(:application_date) { Date.new(Date.today.year, 5, 16)}

          it 'should return month after next month effective date' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq (application_date.next_month + 1.month).beginning_of_month
          end
        end
      end

      context 'when passed date with in open enrollment' do
        context 'and before enrollment monthly due date' do
          let(:application_date) { Date.new(Date.today.year, 12, 15)}

          it 'should return next year begin date' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq application_date.end_of_year + 1.day
          end
        end

        context 'and after enrollment monthly due date' do
          let(:application_date) { Date.new(Date.today.year, 12, 16)}

          it 'should return next year begin date' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq application_date.end_of_year + 1.month + 1.day
          end
        end
      end
    end

    context 'with assistance_year_based_effective_date enabled' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:assistance_year_based_effective_date).and_return(true)
      end
      context 'when passed date for a prospective year application' do
        context 'and the next month is still in the current year' do
          let(:application_date) { Date.new(TimeKeeper.date_of_record.year, 11, 1) }
          let(:assistance_year) { TimeKeeper.date_of_record.year + 1 }

          it 'should return next years first day' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq application_date.end_of_year + 1.day
          end
        end

        context 'and the next month is in the next year' do
          let(:application_date) { Date.new(TimeKeeper.date_of_record.year, 12, 16)}
          let(:assistance_year) { TimeKeeper.date_of_record.year + 1 }

          it 'should return next year begin date' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq application_date.end_of_year + 1.month + 1.day
          end
        end
      end

      context 'when a non prospective year application' do
        context 'and next month in the next year' do
          let(:application_date) { Date.new(Date.today.year, 12, 31)}
          let(:assistance_year) { TimeKeeper.date_of_record.year }

          it 'should return end of current year' do
            expect(result).to be_a(Dry::Monads::Result::Success)
            expect(result.success).to eq application_date.end_of_year
          end
        end
      end
    end
  end
end

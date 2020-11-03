# frozen_string_literal: true

require "rails_helper"

module Operations
  RSpec.describe AgeOffRelaxedEligibility do
    context 'invalid relationship' do
      let(:input_params) do
        {effective_on: Date.new(2021, 2, 1),
         dob: Date.new(2021 - 26, 3, 15),
         market_key: :aca_individual_dependent_age_off,
         relationship_kind: 'parent'}
      end

      it 'should return a failure with a message' do
        expect(subject.call(input_params).failure).to eq('Invalid relationship kind')
      end
    end

    context 'with different ages' do
      context 'age is just below 26 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 2, 1),
           dob: Date.new(2021 - 26, 3, 15),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        context 'age off period is annual' do
          it 'should return success' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
          end
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return success' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
          end
        end
      end

      context 'age is just above 26 and below 27 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 2, 1),
           dob: Date.new(2021 - 26, 1, 1),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        it 'should return Success' do
          expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return failure' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
          end
        end
      end

      context 'age is just above 27 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 1, 2),
           dob: Date.new(2021 - 27, 1, 1),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        it 'should return Failure' do
          expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return failure' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
          end
        end
      end

      context 'age is exactly 26 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 1, 1),
           dob: Date.new(2021 - 26, 1, 1),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        it 'should return success' do
          expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return success' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
          end
        end
      end
    end
  end
end

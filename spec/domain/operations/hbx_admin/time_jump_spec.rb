# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxAdmin::TimeJump, dbclean: :after_each do
  let(:new_date) { TimeKeeper.date_of_record + 1.day }
  let(:params) { { new_date: new_date.strftime('%Y-%m-%d').to_s } }
  let(:result) { subject.call(params) }

  after :each do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  describe 'with valid params' do
    it 'advances the date of record to the new date' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Time Jump is successful, Date is advanced to #{new_date.strftime('%m/%d/%Y')}")
    end
  end

  describe 'with invalid params' do
    context 'when the new date is not a future date' do
      let(:new_date) { TimeKeeper.date_of_record - 1.day }

      it 'returns failure monad' do
        expect(result.failure).to eq('Invalid date, please select a future date')
      end
    end

    context 'when the new date is not a valid date' do
      let(:new_date) { 'invalid date' }
      let(:params) { { new_date: new_date } }

      it 'returns failure monad' do
        expect(result.failure).to eq('Unable to parse date, please enter a valid date')
      end
    end
  end
end
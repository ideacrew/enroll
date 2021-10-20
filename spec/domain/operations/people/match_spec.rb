# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::People::Match, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let(:setting) { double(item: "SOME URI") }

  context 'when there is no record present in db' do
    let(:params) do
      {:first_name => "ivl206",
       :last_name => "206",
       :dob => "1986-09-04",
       :ssn => "763-81-2636"}
    end

    it 'should return zero records' do
      _query_criteria, records, _error = subject.call(params)
      expect(records.count).to eq 0
    end
  end

  context 'when there is one record present in db' do
    let!(:person) do
      FactoryBot.create(:person, :first_name => "ivl206",
                                 :last_name => "206", :dob => "1986-09-04", :ssn => "763-81-2636")
    end

    context 'when querying with same values' do
      let(:params) do
        {:first_name => "ivl206",
         :last_name => "206",
         :dob => "1986-09-04",
         :ssn => "763-81-2636"}
      end

      it 'should return matching record and matching criteria' do
        query_criteria, records, _error = subject.call(params)
        expect(query_criteria).to eq :ssn_present
        expect(records.count).to eq 1
      end
    end

    context 'when querying with different last name' do
      let(:params) do
        {:first_name => "ivl206",
         :last_name => "216",
         :dob => "1986-09-04",
         :ssn => "763-81-2636"}
      end

      context 'and with DC config' do
        it 'should match record and return matching criteria' do
          query_criteria, records, _error = subject.call(params)
          expect(query_criteria).to eq :ssn_present
          expect(records.count).to eq 1
        end
      end

      # context 'and with ME config' do
      #   before :each do
      #     allow(EnrollRegistry).to receive(:feature_enabled?).with(:person_match_policy).and_return(setting)
      #     allow(setting).to receive(:settings).with(:ssn_present).and_return(double(item: ['first_name', 'last_name', 'dob', 'encrypted_ssn']))
      #     allow(EnrollRegistry[:person_match_policy].setting(:ssn_present)).to receive(:item).and_return(['first_name', 'last_name', 'dob', 'encrypted_ssn'])
      #   end
      #   it 'should match record and return matching criteria with error' do
      #     query_criteria, records, error = subject.call(params)
      #     expect(query_criteria).to eq :site_specific_policy
      #     expect(records.count).to eq 1
      #     expect(error.present?).to eq true
      #   end
      # end
    end

    context 'when querying without ssn' do
      let(:params) do
        {:first_name => "ivl206",
         :last_name => "206",
         :dob => "1986-09-04"}
      end

      context 'and with any state based config' do
        it 'should match record and return matching criteria' do
          query_criteria, records, _error = subject.call(params)

          expect(query_criteria).to eq :dob_present
          expect(records.count).to eq 1
        end
      end
    end

    context 'when querying without ssn and different last_name' do
      let(:params) do
        {:first_name => "ivl206",
         :last_name => "206",
         :dob => "1986-09-04"}
      end

      context 'and with any state based config' do
        it 'should match record and return matching criteria' do
          query_criteria, records, _error = subject.call(params)

          expect(query_criteria).to eq :dob_present
          expect(records.count).to eq 1
        end
      end
    end
  end
end

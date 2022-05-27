# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::ZipcodeHelper, :type => :helper, dbclean: :after_each do

  let(:zipcode_mappings) { ::FinancialAssistance::ZipcodeHelper::ZIPCODE_MAPPINGS }

  context 'zipcode mappings hash' do
    it 'should exist and not be empty' do
      expect(zipcode_mappings.present?).to be_truthy
    end

    it 'should only have city, county and geocode keys in each value hash' do
      value_keys = zipcode_mappings.values.map(&:keys)
      bad_keys = value_keys.select {|keys| keys != [:city, :county, :geocode]}
      expect(bad_keys.empty?).to be_truthy
    end
  end

  context 'zipcode_to_geocode' do
    context 'zipcode is not present in hash' do
      it 'should return nil' do
        zip = "XXXXX"
        expect(zipcode_to_geocode(zip)).to eq nil
      end
    end

    context 'zipcode is present in hash' do
      it 'should return a string' do
        zip = zipcode_mappings.keys.first
        expect(zipcode_to_geocode(zip)).to be_instance_of(String)
      end
    end
  end

  context 'city_to_county' do
    context 'city is not present in hash' do
      it 'should return nil' do
        city = "XXXXX"
        expect(city_to_county(city)).to eq nil
      end
    end

    context 'zipcode is present in hash' do
      it 'should return a string' do
        city = zipcode_mappings.values.first[:city]
        expect(city_to_county(city)).to be_instance_of(String)
      end
    end

    context 'five_digit_format' do
      context 'given 9-digit zip' do
        it 'should return first five digits' do
          zip = '12345-1234'
          expect(five_digit_format(zip)).to eq('12345')
        end
      end
    end
  end
end
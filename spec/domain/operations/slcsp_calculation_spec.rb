# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

RSpec.describe Operations::SlcspCalculation, type: :model, dbclean: :after_each do
  include_context 'family with 2 family members with county_zip, rating_area & service_area'
  include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'
  let(:one_household) do
    {
      family_id: family.id,
      effective_date: start_of_year,
      households: [
        {
          household_id: 'a12bs6dbs1',
          members: [
            {
              family_member_id: family_member1.id,
              relationship_with_primary: 'self'
            },
            {
              family_member_id: family_member2.id,
              relationship_with_primary: 'spouse'
            }
          ]
        }
      ]
    }
  end

  let(:person_rating_address) { person1.rating_address }

  let!(:valid_params) do
    {:householdConfirmation => true, :householdCount => 1, :taxYear => start_of_year.year, :state => "ME",
     :members => [{:primaryMember => true,
                   :name => "Mark",
                   :relationship => "self",
                   :dob => {:month => "1", :day => "1", :year => "1979"},
                   :residences => [{:county => {:zipcode => person_rating_address.zip,
                                                :name => person_rating_address.county,
                                                :fips => "23005",
                                                :state => person_rating_address.state},
                                    :months => {:jan => true,
                                                :feb => true,
                                                :mar => true,
                                                :apr => true,
                                                :may => true,
                                                :jun => true,
                                                :jul => true,
                                                :aug => true,
                                                :sep => true,
                                                :oct => true,
                                                :nov => true,
                                                :dec => true}}],
                   :coverage => {:jan => true,
                                 :feb => true,
                                 :mar => true,
                                 :apr => true,
                                 :may => true,
                                 :jun => true,
                                 :jul => true,
                                 :aug => true,
                                 :sep => true,
                                 :oct => true,
                                 :nov => true,
                                 :dec => true}}]}
  end

  before do
    ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  end

  context 'with valid params' do
    it 'should return a success' do
      result = subject.call(valid_params)
      expect(result.success?).to be_truthy
    end

    it 'should not be zero' do
      result = subject.call(valid_params)
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        expect(result.value![month_key]).to be > 0
      end
    end
  end

  context 'with uber payload' do
    let!(:uber_payload) do
      {:householdConfirmation => true, :householdCount => 1, :taxYear => start_of_year.year, :state => "ME",
       :members => [{:primaryMember => true,
                     :name => "Mark",
                     :relationship => "self",
                     :dob => {:month => "1", :day => "1", :year => "1979"},
                     :residences => [{ :absent => true,
                                       :county => {:zipcode => "",
                                                   :name => "",
                                                   :fips => "",
                                                   :state => ""},
                                       :months => {:jan => true,
                                                   :feb => false,
                                                   :mar => false,
                                                   :apr => false,
                                                   :may => false,
                                                   :jun => false,
                                                   :jul => false,
                                                   :aug => false,
                                                   :sep => true,
                                                   :oct => false,
                                                   :nov => false,
                                                   :dec => false}},
                                     {:absent => false,
                                      :county => {:zipcode => person_rating_address.zip,
                                                  :name => person_rating_address.county,
                                                  :fips => "23005",
                                                  :state => person_rating_address.state},
                                      :months => {:jan => false,
                                                  :feb => true,
                                                  :mar => true,
                                                  :apr => true,
                                                  :may => true,
                                                  :jun => true,
                                                  :jul => true,
                                                  :aug => true,
                                                  :sep => false,
                                                  :oct => false,
                                                  :nov => false,
                                                  :dec => false}},
                                     {:county => {:zipcode => "04003",
                                                  :name => "Cumberland",
                                                  :fips => "23005",
                                                  :state => "ME"},
                                      :months => {:jan => false,
                                                  :feb => false,
                                                  :mar => false,
                                                  :apr => false,
                                                  :may => false,
                                                  :jun => false,
                                                  :jul => false,
                                                  :aug => false,
                                                  :sep => false,
                                                  :oct => false,
                                                  :nov => true,
                                                  :dec => false}},
                                     {:county => {:zipcode => "43",
                                                  :name => "The answer to life, the universe, and everything",
                                                  :fips => "23005",
                                                  :state => "NA"},
                                      :months => {:jan => false,
                                                  :feb => false,
                                                  :mar => false,
                                                  :apr => false,
                                                  :may => false,
                                                  :jun => false,
                                                  :jul => false,
                                                  :aug => false,
                                                  :sep => false,
                                                  :oct => false,
                                                  :nov => false,
                                                  :dec => true}}],
                     :coverage => {:jan => true,
                                   :feb => true,
                                   :mar => true,
                                   :apr => true,
                                   :may => true,
                                   :jun => true,
                                   :jul => false,
                                   :aug => true,
                                   :sep => true,
                                   :oct => false,
                                   :nov => true,
                                   :dec => true}},
                    {:primaryMember => false,
                     :name => "Nella",
                     :relationship => "spouse",
                     :dob => {:month => "1", :day => "2", :year => "1980"},
                     :residences => [{:county => {:zipcode => person_rating_address.zip,
                                                  :name => person_rating_address.county,
                                                  :fips => "23005",
                                                  :state => person_rating_address.state},
                                      :months => {:jan => true,
                                                  :feb => true,
                                                  :mar => true,
                                                  :apr => true,
                                                  :may => true,
                                                  :jun => true,
                                                  :jul => true,
                                                  :aug => true,
                                                  :sep => true,
                                                  :oct => true,
                                                  :nov => true,
                                                  :dec => true}}],
                     :coverage => {:jan => false,
                                   :feb => false,
                                   :mar => false,
                                   :apr => false,
                                   :may => false,
                                   :jun => false,
                                   :jul => false,
                                   :aug => true,
                                   :sep => true,
                                   :oct => false,
                                   :nov => true,
                                   :dec => true}}]}

    end

    it 'should return a success' do
      result = subject.call(uber_payload)
      expect(result.success?).to be_truthy
    end

    it 'should not be zero' do
      result = subject.call(uber_payload)
      expect(result.value![:jan]).to eq("Lived in another country or was deceased")
      expect(result.value![:jul]).to be_nil
      expect(result.value![:aug]).to eq(1180)
      expect(result.value![:oct]).to eq("Lived in a different state")
      expect(result.value![:nov]).to eq(1180)
    end
  end

  context 'with an out of state period' do
    let!(:valid_params) do
      {:householdConfirmation => true, :householdCount => 1, :taxYear => start_of_year.year, :state => "ME",
       :members => [{:primaryMember => true,
                     :name => "Mark",
                     :relationship => "self",
                     :dob => {:month => "1", :day => "1", :year => "1979"},
                     :residences => [{:county => {:zipcode => person_rating_address.zip,
                                                  :name => person_rating_address.county,
                                                  :fips => "23005",
                                                  :state => person_rating_address.state},
                                      :months => {:jan => true,
                                                  :feb => true,
                                                  :mar => false,
                                                  :apr => true,
                                                  :may => true,
                                                  :jun => true,
                                                  :jul => true,
                                                  :aug => true,
                                                  :sep => true,
                                                  :oct => true,
                                                  :nov => true,
                                                  :dec => true}},
                                     {:county => {:zipcode => person_rating_address.zip,
                                                  :name => person_rating_address.county,
                                                  :fips => "23005",
                                                  :state => "ANOTHER RANDOM STATE"},
                                      :months => {:jan => false,
                                                  :feb => false,
                                                  :mar => true,
                                                  :apr => false,
                                                  :may => false,
                                                  :jun => false,
                                                  :jul => false,
                                                  :aug => false,
                                                  :sep => false,
                                                  :oct => false,
                                                  :nov => false,
                                                  :dec => false}}],
                     :coverage => {:jan => true,
                                   :feb => true,
                                   :mar => true,
                                   :apr => true,
                                   :may => true,
                                   :jun => true,
                                   :jul => true,
                                   :aug => true,
                                   :sep => true,
                                   :oct => true,
                                   :nov => true,
                                   :dec => true}}]}
    end

    it 'should return a success' do
      result = subject.call(valid_params)
      expect(result.success?).to be_truthy
    end

    it 'has results except for the out of state period' do
      result = subject.call(valid_params)
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        if i == 3
          expect(result.value![month_key]).to eq "Lived in a different state"
        else
          expect(result.value![month_key]).to be > 0
        end
      end
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::AddressValidator, :type => :helper, dbclean: :after_each do

  context '#has_in_state_home_addresses?', dbclean: :after_each do

    context 'for in state addresses' do

      let!(:address_attributes) do
        {0 => {
          "address_1" => "3 Awesome Street",
          "address_2" => "#300",
          "address_3" => "",
          "county" => "Kennebec",
          "country_name" => "",
          "quadrant" => "",
          "kind" => "home",
          "city" => "Augusta",
          "state" => "DC",
          "zip" => "04332-6626"
        }}
      end

      it "should return true" do
        expect(has_in_state_home_addresses?(address_attributes)).to eq true
      end
    end

    context 'for out of state addresses' do

      let!(:address_attributes) do
        {0 => {
          "address_1" => "3 Awesome Street",
          "address_2" => "#300",
          "address_3" => "",
          "county" => "Kennebec",
          "country_name" => "",
          "quadrant" => "",
          "kind" => "home",
          "city" => "Augusta",
          "state" => "MA",
          "zip" => "04332-6626"
        }}
      end

      it "should return true" do
        expect(has_in_state_home_addresses?(address_attributes)).to eq false
      end
    end

    context 'for nil addresses' do
      it "should return true" do
        expect(has_in_state_home_addresses?(nil)).to eq false
      end
    end

    context 'for empty hash addresses' do

      let!(:address_attributes) do
        {}
      end

      it "should return true" do
        expect(has_in_state_home_addresses?(nil)).to eq false
      end
    end
  end
end

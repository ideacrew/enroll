# frozen_string_literal: true

require 'rails_helper'
RSpec.describe "events/addresses/_address.haml.erb", dbclean: :after_each do
  let(:individual) { FactoryBot.build_stubbed :person, addresses: [address] }
  let(:address) { FactoryBot.build_stubbed :address, county: 'Aroostook', state: 'ME'}
  let(:contact_address) { individual.contact_addresses.first }
  let!(:us_county) { BenefitMarkets::Locations::CountyFips.create({ state_postal_code: 'ME',  county_fips_code: '23003', county_name: 'Aroostook'}) }
  context 'county fips code is enabled' do
    before do
      EnrollRegistry[:enroll_app].setting(:county_fips_code_enabled).stub(:item).and_return(true)
      render :partial => "events/addresses/address", :collection => individual.contact_addresses
      @doc = Nokogiri::XML(rendered)
    end
    it "should have location county code" do
      expect(@doc.xpath("//address/location_county_code").count).to eq 1
      expect(@doc.xpath("//address/location_county_code").text).to eq us_county.county_fips_code
    end
  end
  context 'county fips code is disabled' do
    before do
      EnrollRegistry[:enroll_app].setting(:county_fips_code_enabled).stub(:item).and_return(false)
      render :partial => "events/addresses/address", :collection => individual.contact_addresses
      @doc = Nokogiri::XML(rendered)
    end
    it "should have location county code" do
      expect(@doc.xpath("//address/location_county_code").count).to eq 0
    end
  end
end

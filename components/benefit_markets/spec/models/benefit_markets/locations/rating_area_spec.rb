require 'rails_helper'

module BenefitMarkets
  # TODO: Figure out how to refactor with ResourceRegistry
  RSpec.describe Locations::RatingArea do
    before :each do
      DatabaseCleaner.clean
    end
    describe "given nothing" do
      before :each do
        subject.valid?
      end

      it "requires an active year" do
        expect(subject.errors.has_key?(:active_year)).to be_truthy
      end

      it "requires an exchange provided code" do
        expect(subject.errors.has_key?(:exchange_provided_code)).to be_truthy
      end

      it "requires a geographic boundry to be specified" do
        expect(subject.errors[:base]).to include("a location covered by the rating area must be specified")
      end
    end

    describe "which covers the entire administrative area" do
      subject { Locations::RatingArea.new(covered_states: ["MA"]) }

      before :each do
        subject.valid?
      end

      it "is satisfied location has been provided" do
        expect(subject.errors[:base]).not_to include("a location covered by the rating area must be specified")
      end
    end

    describe "given a county zip pair" do
      subject { Locations::RatingArea.new(county_zip_ids: [BSON::ObjectId.new]) }

      before :each do
        subject.valid?
      end

      it "is satisfied location has been provided" do
        expect(subject.errors[:base]).not_to include("a location covered by the rating area must be specified")
      end
    end

    describe "created for a given zip code and county in a state", :dbclean => :after_each do
      let(:county_zip) { ::BenefitMarkets::Locations::CountyZip.create!(county_name: "Hampshire", zip: "01001", state: "MA") }
      let(:rating_area) { ::BenefitMarkets::Locations::RatingArea.create!(active_year: TimeKeeper.date_of_record.year, county_zip_ids: [county_zip.id], exchange_provided_code: "MA0") }

      let(:address_outside_county) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Baltimore",
          :state => "MA"
        )
      }
      let(:address_outside_zip) {
        OpenStruct.new(
          :zip => "01555",
          :county => "Hampshire",
          :state => "MA"
        )
      }
      let(:address_outside_state) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MD"
        )
      }
      let(:matching_address) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MA"
        )
      }

      after(:each) do
        county_zip.destroy
        rating_area.destroy
      end

      context 'single rating area model' do

        before :each do
          allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(settings: double(item: 'single')))
        end

        it "will return rating_area based on exchange when given an address not in that county" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_county)
          expect(rating_areas.to_a).to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that zip code" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_zip)
          expect(rating_areas.to_a).to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that state" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_state)
          expect(rating_areas.to_a).to include(rating_area)
        end
      end

      context 'county based rating area model' do

        before :each do
          allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(settings: double(item: 'county')))
        end

        it "will return rating_area based on exchange when given an address not in that county" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_county)
          expect(rating_areas.to_a).not_to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that zip code but in county" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_zip)
          expect(rating_areas.to_a).to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that state" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_state)
          expect(rating_areas.to_a).not_to include(rating_area)
        end
      end

      context 'zipcode based rating area model' do

        before :each do
          allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(settings: double(item: 'zipcode')))
        end

        it "will return rating_area based on exchange when given an address not in that county but in zip" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_county)
          expect(rating_areas.to_a).to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that zip" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_zip)
          expect(rating_areas.to_a).not_to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that state" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_state)
          expect(rating_areas.to_a).not_to include(rating_area)
        end
      end

      context 'mixed rating area model' do

        before :each do
          allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(settings: double(item: 'mixed')))
        end

        it "will return rating_area based on exchange when given an address not in that county" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_county)
          expect(rating_areas.to_a).not_to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that zip code" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_zip)
          expect(rating_areas.to_a).not_to include(rating_area)
        end

        it "will return rating_area based on exchange when given an address not in that state" do
          rating_area
          rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_state)
          expect(rating_areas.to_a).not_to include(rating_area)
        end
      end

      it "is found when a matching address is provided" do
        rating_area
        rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(matching_address)
        expect(rating_areas.to_a).to include(rating_area)
      end
    end

    describe "created for a given state", :dbclean => :after_each do
      let(:app_setting) {double(setting: double(item: :dc), settings: double(item: 'single'))}

      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(app_setting)
      end

      let(:rating_area) { ::BenefitMarkets::Locations::RatingArea.create!(active_year: TimeKeeper.date_of_record.year, covered_states: ["MA"], exchange_provided_code: "MA0") }

      let(:address_outside_state) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MD"
        )
      }
      let(:matching_address) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MA"
        )
      }

      it "will return rating area based on exchange when given an address not in that state" do
        rating_area
        rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address_outside_state)
        if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
          expect(rating_areas.to_a).not_to include(rating_area)
        else
          expect(rating_areas.to_a).to include(rating_area)
        end
      end

      it "is found when a matching address is provided" do
        rating_area
        rating_areas = ::BenefitMarkets::Locations::RatingArea.rating_area_for(matching_address)
        expect(rating_areas.to_a).to include(rating_area)
      end
    end
  end
end

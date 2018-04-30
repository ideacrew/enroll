require 'rails_helper'

module BenefitMarkets
  RSpec.describe Locations::RatingArea do
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
  end
end

require "rails_helper"

describe FamilySearch, :dbclean => :after_each do

  describe "with a single, simple family" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:person) { family.primary_family_member.person }

    subject { FamilySearch.where("value.primary_member.last_name" => person.last_name).first }

    it "finds the family" do
      expect(subject._id).to eq family._id
    end
  end

  describe "with two families" do
    let(:family_1) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:family_2) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:person_1) { family_1.primary_family_member.person }
    let(:person_2) { family_2.primary_family_member.person }

    let(:found_family_1) { FamilySearch.where("value.primary_member.last_name" => person_1.last_name).first }
    let(:found_family_2) { FamilySearch.where("value.primary_member.last_name" => person_2.last_name).first }

    before :each do
      # Trick to ensure both are loaded before each test
      found_family_1
      found_family_2
    end

    it "should have both family records" do
      expect(FamilySearch.count).to eq 2
    end

    it "finds the first family" do
      expect(found_family_1._id).to eq family_1._id
    end

    it "finds the first family" do
      expect(found_family_2._id).to eq family_2._id
    end
  end
end

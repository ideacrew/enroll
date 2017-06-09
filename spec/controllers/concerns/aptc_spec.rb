require 'rails_helper'

class FakesController < ApplicationController
  include Aptc
end

describe FakesController do
  let(:person) {FactoryGirl.build(:person)}

  context "#get_shopping_tax_household_from_person" do
    it "should get nil without person" do
      expect(subject.get_shopping_tax_household_from_person(nil, 2015)).to eq nil
    end

    it "should get nil when person without consumer_role" do
      allow(person).to receive(:has_active_consumer_role?).and_return true
      expect(subject.get_shopping_tax_household_from_person(person, 2015)).to eq nil
    end
  end

  describe "get_tax_household_from_family_members" do
    let!(:person1) { FactoryGirl.create(:person, :with_family, :with_consumer_role) }
    let!(:family)  { person1.primary_family }
    let!(:family_member1) { family.primary_applicant }
    let!(:family_member2) { FactoryGirl.create(:family_member, family: family) }
    let!(:family_member3) { FactoryGirl.create(:family_member, family: family) }
    let!(:family_member4) { FactoryGirl.create(:family_member, family: family) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:tax_household1) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
    let!(:tax_household2) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
    let!(:tax_household3) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
    let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
    let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id) }
    let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member3.id) }
    let!(:applicant4) { FactoryGirl.create(:applicant, tax_household_id: tax_household3.id, application: application, family_member_id: family_member4.id) }

    context "get_tax_household_from_family_members" do
      it "should return all the tax housholds of the given family members" do
        allow(person1).to receive(:has_active_consumer_role?).and_return true
        family_member_ids = {"0" => family_member1.id.to_s, "1" => family_member2.id.to_s , "2" => family_member3.id.to_s, "3" => family_member4.id.to_s}
        expect(subject.get_tax_household_from_family_members(person1, family_member_ids)).to eq [tax_household1, tax_household2, tax_household3]
      end
    end

    context "total_aptc_on_tax_households" do
      it "should return 0 when there are no enrollments" do
        tax_households = [ applicant1.tax_household, applicant3.tax_household]
        expect(subject.total_aptc_on_tax_households(tax_households, nil)).to eq 0
      end
    end
  end
end

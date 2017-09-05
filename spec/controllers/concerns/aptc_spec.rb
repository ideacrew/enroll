require 'rails_helper'


class FakesController < ApplicationController
  include Aptc
end

RSpec.describe FakesController, :type => :controller do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow(person).to receive_message_chain("primary_family.enrolled_hbx_enrollments").and_return([hbx_enrollment_one])
    allow(person.primary_family).to receive(:active_approved_application).and_return(application)
  end

      let!(:person) {FactoryGirl.create(:person, :with_family, :with_consumer_role)}
      let!(:family)  { person.primary_family}
      let(:application) { FactoryGirl.create(:application, family: family) }
      let(:hbx_enrollment_one) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }
      let!(:primary_member) { family.primary_applicant}
      let!(:family_member1) { FactoryGirl.create(:family_member, family: family) }
      let!(:family_member2) { FactoryGirl.create(:family_member, family: family) }
      let!(:household) { family.households.first }
      let!(:tax_household1) {FactoryGirl.create(:tax_household, application_id: application.id,  household: household, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
      let!(:tax_household2) {FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
      let!(:tax_household3) {FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
      let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family.primary_applicant.id) }
      let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member1.id) }
      let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household3.id, application: application, family_member_id: family_member2.id) }

  describe FakesController do
    context "#get_shopping_tax_household_from_person" do
      it "should get nil without person" do
        expect(subject.get_shopping_tax_households_from_person(nil, 2017)).to eq nil
      end

      it "should get taxhousehold with person" do
        expect(subject.get_shopping_tax_households_from_person(person, 2017)).to eq tax_household1
      end

      it "should get nil when person without consumer_role" do
        allow(person).to receive(:has_active_consumer_role?).and_return false
        expect(subject.get_shopping_tax_households_from_person(person, 2017)).to eq nil
      end
    end

    describe "get_tax_household_from_family_members" do
      context "get_tax_household_from_family_members" do
        it "should return all the tax housholds of the given family members" do
          allow(person).to receive(:has_active_consumer_role?).and_return true
          family_member_ids = {"0" => primary_member.id.to_s, "1" => family_member1.id.to_s, "2" => family_member2.id.to_s}
          expect(subject.get_tax_households_from_family_members(person, family_member_ids)).to eq [tax_household1, tax_household2, tax_household3]
        end

        it "should return no tax housholds for no family members" do
          expect(subject.get_tax_households_from_family_members(person, [])).to eq []
        end
      end

      context "total_aptc_on_tax_households" do
        it "should return 0 when there are no enrollments" do
          tax_households = [applicant1.tax_household, applicant3.tax_household]
          expect(subject.total_aptc_on_tax_households(tax_households, nil)).to eq 0
        end
      end
    end
  end
end


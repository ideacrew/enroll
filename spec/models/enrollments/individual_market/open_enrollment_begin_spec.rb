require 'rails_helper'

RSpec.describe Enrollments::IndividualMarket::OpenEnrollmentBegin, type: :model do

  context "Given a database of Families" do

    it "the collection should include ten or more Families"
    it "at least one Family with both active Individual Market Health and Dental plan Enrollments"
    it "at least one Family with an active 'Individual Market Health plan Enrollment only'"
    it "at least one Family with an active 'Assisted Individual Market Health plan Enrollment only'"
    it "at least one Family with an active 'Individual Market Catastrophic plan Enrollment only'"
    it "at least one Family with two active Individual Market Health plan Enrollments, one which is responsible person"
    it "at least one Family with active Individual and SHOP Market Health plan Enrollments"
    it "at least one Family with active Individual Market Dental and SHOP Market Health plan Enrollments"
    it "at least one Family with a terminated 'Individual Market Health plan Enrollment only'"
    it "at least one Family with a terminated 'Individual Market Dental plan Enrollment only'"
    it "at least one Family with a future terminated 'Individual Market Health plan Enrollment only'"
    it "at least one Family with a future terminated 'Individual Market Dental-only plan Enrollment'"


    context "and only Families eligible for enrollment auto renewal processing are selected from database" do

      it "the set should include Families with both active Individual Market Health and Dental plan Enrollments"
      it "the set should include Families with an active 'Individual Market Health plan Enrollment only'"
      it "the set should include Families with active Individual and SHOP Market Health plan Enrollments"
      it "the set should include Families with active Individual Market Dental and SHOP Market Health plan Enrollments"

      it "the set should not include Families with a terminated 'Individual Market Health plan Enrollment only'"
      it "the set should not include Families with a terminated 'Individual Market Dental plan Enrollment only'"
      it "the set should not include Families a future terminated 'Individual Market Health plan Enrollment only'"
      it "the set should not include Families a future terminated Individual Market Dental-only plan Enrollment"


      context "and the Family with both active Individual Market Health and Dental plan Enrollments is renewed" do
        it "should create a new Health enrollment"
        it "the new enrollment should have a Health plan valid for the upcoming calendar year"
        it "the new enrollment should have a Jan 1 of next calendar year effective date"
        it "the new enrollment should include all the enrollees from the current plan year"
        it "the new enrollment should have a calculatable premium"

        it "should create a new Dental plan enrollment"
        it "the new enrollment should have a Dental plan valid for the upcoming calendar year"
        it "the new enrollment should have a Jan 1 of next calendar year effective date"
        it "the new enrollment should include all the enrollees from the current plan year"
        it "the new enrollment should have a calculatable premium"

        context "and one child dependent is over age 26 on Jan 1" do
          it "the child should be member of the extended_family_coverage_household"
          it "the child should not be member of the immediate_family_coverage_household"
          it "the child should not be included in the new health enrollment group"
          it "the child should not be included in the new dental enrollment group"
        end

        context "and one child dependent is over age 26 Jan 1 and disabled" do
          it "the child should not be member of the extended_family_coverage_household"
          it "the child should be member of the immediate_family_coverage_household"
          it "the child should be included in the new health enrollment group"
          it "the child should be included in the new dental enrollment group"
        end
      end

      context "and the Family with an active 'Assisted Individual Market Health plan Enrollment only' is renewed" do
        it "the renewed enrollment should have the same APTC percentage as the base enrollment"

        context "and there is a financial assistance redetermination valid for the new plan year" do
          it "the Family's TaxHousehold should have a financial assistance redetermination valid for the new plan year"
        end

        context "and there is not a financial assistance redetermination valid for the new plan year" do
          it "the renewed enrollment should have $0 APTC for the new plan year"
        end
      end

      context "and the Family with an active 'Individual Market Catastrophic plan Enrollment only' is renewed" do

        context "and none of the enrollment members are over age 30 on Jan 1" do
          it "the new enrollment should have a comparable Catastrophic plan"
        end

        context "and at least one of the enrollment members are over age 30 on Jan 1" do
          it "should renew enrollment into a mapped Bronze plan??"
        end
      end

      context "and the Family with two active Individual Market Health plan Enrollments, one which is responsible person is renewed" do
        it "should produce a new standard enrollment"
        it "should produce a new responsible person enrollment"
      end

      context "and the Family with active Individual and SHOP Market Health plan Enrollments" do
        it "should produce a new Individual health enrollment"
        it "should not produce a new SHOP health enrollment"
      end

      context "and the Family with active Individual Market Dental and SHOP Market Health plan Enrollments" do
        it "should produce a new Individual dental enrollment"
        it "should not produce a new SHOP health enrollment"
      end

    end
  end

  context "Today is 30 days prior to the first day of the Annual Open Enrollment period for the HBX Individual Market" do
    it "should generate and transmit renewal notices"
  end

  context "Today is the first day of the Annual Open Enrollment period for the HBX Individual Market" do
    context "and health and dental plans and rates for the new calendar year are loaded" do
      context "and comparable plan mapping from this calendar year to the next calendar year is present" do
        context "and Assisted QHP Families have finanancial eligibility redetermined for the next calendar year" do
        end
      end
    end
  end


end

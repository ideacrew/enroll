require 'rails_helper'

RSpec.describe TaxHouseholdMember, type: :model do

  describe ".new" do
    it "should set default attribute values" do
      expect(TaxHouseholdMember.new.is_ia_eligible).to be false
      expect(TaxHouseholdMember.new.is_medicaid_chip_eligible).to be false
      expect(TaxHouseholdMember.new.is_subscriber).to be false
      expect(TaxHouseholdMember.new.is_without_assistance).to be false
      expect(TaxHouseholdMember.new.is_totally_ineligible).to be false
    end

    it "should not set applicant_id" do
      expect(TaxHouseholdMember.new.applicant_id).to be nil
    end
  end

  describe "instance methods" do
    before :all do
      @person = FactoryGirl.create(:person)
      @family = FactoryGirl.create(:family, :with_primary_family_member, person: @person)
      @plan = FactoryGirl.create(:plan, :with_premium_tables, active_year: 2017, hios_id: "86052DC0400001-01")
      @application = FactoryGirl.create(:application, family: @family)
      @family_member1 = FactoryGirl.create(:family_member, family: @family)
      @household = FactoryGirl.create(:household, family: @family)
      @tax_household = FactoryGirl.create(:tax_household, household: @household)
      @tax_household_member = @tax_household.tax_household_members.create
      @eligibility_determination1 = FactoryGirl.create(:eligibility_determination, tax_household: @tax_household,  determined_on: TimeKeeper.date_of_record)
    end

    context '.create' do
      it { should be_embedded_in(:tax_household) }

      it "should set a id" do
        expect(@tax_household_member._id).not_to be nil
      end

      it "should be valid" do
        expect(@tax_household_member.valid?).to be true
      end
    end

    context '#eligibility_determinations' do
      it 'should return eligibility_determinations' do
        expect(@tax_household_member.eligibility_determinations ).to include
        @eligibility_determination1
      end
    end

    context '#is_ia_eligible?' do
      it 'should return eligibility status' do
        expect(@tax_household_member.is_ia_eligible? ).to be false
      end
    end

    context '#non_ia_eligible?' do
      it 'should return non ia eligibility' do
        expect(@tax_household_member.non_ia_eligible? ).to be false
      end
    end

    context '#is_subscriber?' do
      it 'should return eligibility_determinations' do
        expect(@tax_household_member.is_subscriber? ).to be false
      end
    end

    context '#family' do
      it "should return family" do
        expect(@tax_household_member.family).to eq @family
      end
    end

    context '#strictly_boolean' do
      it "should return family" do
        @tax_household_member.strictly_boolean
        expect(@tax_household_member.errors.messages).to be {}
      end
    end
  end
end
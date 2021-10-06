require "rails_helper"

RSpec.describe Insured::EmployeeRolesHelper, :type => :helper do
  describe "#calculate_age_by_dob" do
    context "return age by dob" do
      it "with now month less than dob month" do
        now = TimeKeeper.date_of_record
        dob = TimeKeeper.date_of_record - 10.years - 1.month
        expect(helper.calculate_age_by_dob(dob)).to eq 10
      end

      it "with now month more than dob month" do
        now = TimeKeeper.date_of_record
        dob = TimeKeeper.date_of_record - 10.years + 1.month
        expect(helper.calculate_age_by_dob(dob)).to eq 9
      end

      context "with now month equal dob month" do
        it "and now day less than dob day" do
          now = TimeKeeper.date_of_record
          dob = TimeKeeper.date_of_record - 10.years - 1.day
          expect(helper.calculate_age_by_dob(dob)).to eq 10
        end

        it "and now day more than dob day" do
          now = TimeKeeper.date_of_record
          dob = TimeKeeper.date_of_record - 10.years + 1.day
          expect(helper.calculate_age_by_dob(dob)).to eq 9
        end

        it "and now day equal dob day" do
          now = TimeKeeper.date_of_record
          dob = TimeKeeper.date_of_record - 10.years
          expect(helper.calculate_age_by_dob(dob)).to eq 10
        end
      end
    end
  end

  describe "#coverage_relationship_check" do
    let(:orb) {["employee", "spouse", "child_under_26"]}
    let(:spouse) { double(primary_relationship: "ex-spouse") }
    let(:new_effective_on) {TimeKeeper.date_of_record}
    let(:domestic_partner) { double(primary_relationship: "life_partner") }
    let(:child) {double(primary_relationship: "ward", dob: TimeKeeper.date_of_record)}

    it "offered_relationship_benefits include the relationship of family_member" do
      expect(helper.coverage_relationship_check(orb, spouse, new_effective_on)).to be_truthy
    end

    it "offered_relationship_benefits not include the relationship of family_member" do
      expect(helper.coverage_relationship_check(orb, domestic_partner, new_effective_on)).to be_falsey
    end

    context "with child" do
      it "and age over 26" do
        allow(helper).to receive(:calculate_age_by_dob).and_return(30)
        expect(helper.coverage_relationship_check(orb, child, new_effective_on)).to be_falsey
      end

      it "and age under 26" do
        allow(helper).to receive(:calculate_age_by_dob).and_return(10)
        expect(helper.coverage_relationship_check(orb, child, new_effective_on)).to be_truthy
      end

      it "child age under 26 enrollment effective_on is after child entered 26 years" do
        allow(helper).to receive(:calculate_age_by_dob).and_return(25)
        allow(child).to receive(:dob).and_return TimeKeeper.date_of_record - 26.years
        expect(helper.coverage_relationship_check(orb, child, new_effective_on)).to be_falsey
      end

    end
  end

  describe "#show_market_name_by_enrollment" do
    let(:enrollment) { HbxEnrollment.new }
    context "for shop" do
      it "under employer_sponsored_cobra" do
        enrollment.kind = 'employer_sponsored_cobra'
        expect(helper.show_market_name_by_enrollment(enrollment)).to eq 'Employer Sponsored COBRA/Continuation'
      end

      it "under employer_sponsored" do
        enrollment.kind = 'employer_sponsored'
        expect(helper.show_market_name_by_enrollment(enrollment)).to eq 'Employer Sponsored'
      end
    end

    it "for individual" do
      expect(helper.show_market_name_by_enrollment(enrollment)).to eq 'Individual'
    end

    it "with nil" do
      expect(helper.show_market_name_by_enrollment(nil)).to eq ''
    end
  end


  describe "#show_metal_level_by_enrollment" do

    let(:dental_plan){ FactoryBot.create(:benefit_markets_products_dental_products_dental_product, dental_level: 'high') }
    let(:health_plan){ FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :bronze) }
    context "for shop" do

      it "under employer_sponsored_cobra" do
        expect(helper.show_metal_level_by_enrollment(dental_plan)).to eq :High
      end

      it "under employer_sponsored" do
        expect(helper.show_metal_level_by_enrollment(health_plan)).to eq :Bronze
      end
    end
  end
end

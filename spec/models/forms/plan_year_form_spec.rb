require 'rails_helper'

describe ::Forms::PlanYearForm, "when newly created" do
  subject { ::Forms::PlanYearForm.new(PlanYear.new) }

  context "validation" do
    before :each do
      subject.valid?
    end

    [:start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on].each do |attr|
      it "should have errors on #{attr}" do
        expect(subject).to have_errors_on(attr.to_sym)
      end
    end
  end

  context "plans" do
    let(:carrier_profile) {FactoryGirl.build(:carrier_profile)}

    before :each do
      Plan.delete_all
      @plan = FactoryGirl.create(:plan, active_year: Time.now.year, market: "shop", coverage_kind: "health", carrier_profile: carrier_profile, metal_level: "silver")
      FactoryGirl.create(:plan, active_year: (Time.now.year - 1), carrier_profile: carrier_profile)
      FactoryGirl.create(:plan, market: "individual", carrier_profile: carrier_profile)
      FactoryGirl.create(:plan, coverage_kind: "dental", carrier_profile: carrier_profile)
    end

    it "carrier_plans_for" do
      expect(subject.carrier_plans_for(carrier_profile.id)).to eq [@plan]
    end

    it "metal_level_plans_for" do
      expect(subject.metal_level_plans_for("silver")).to eq [@plan]
    end
  end
end

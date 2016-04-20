require 'rails_helper'

RSpec.describe HbxAdmin, :type => :model do
  
  context "APTC / CSR : build grid values" do
    
    let(:family)       { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:months_array) {Date::ABBR_MONTHNAMES.compact}
    
    let(:hbx_enrollment) {HbxEnrollment.create}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}


    context "plan-premium" do
      let(:plan_premium_hash_value_first_when_no_enrollment) { ["Jan", false] }

      it "should return a hash with 'false' value wheh there is no active enrollment" do
        allow(family).to receive(:active_household).and_return family.active_household
        expect(HbxAdmin.build_plan_premium_values(family, months_array).first).to eq plan_premium_hash_value_first_when_no_enrollment
      end

    end

    context "aptc-applied" do

      let(:aptc_applied_hash_value_when_no_enrollment) { ["Jan", 0] }
      let(:aptc_applied_hash_value_when_active_enrollment) { ["Jan", 10] }
      
      let(:tax_household) {double}
      let!(:hbx_without_aptc) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 0)}
      let!(:hbx_with_aptc) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      
      let(:hbx_enrollment) {HbxEnrollment.create}
      let(:household) {FactoryGirl.create(:household, family: family)}
      let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', determined_on: TimeKeeper.date_of_record.beginning_of_year, max_aptc: Money.new(511, "USD"))}

      it "should return a hash with '0' value when there is no active enrollment" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household).and_return tax_household
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination]
        expect(HbxAdmin.build_aptc_applied_values(family, months_array).first).to eq aptc_applied_hash_value_when_no_enrollment
      end

      it "should return a hash with value > 0  when there an active enrollment" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household).and_return tax_household
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination]
        household.reload
        expect(household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)).to eq [hbx_with_aptc] 
        expect(HbxAdmin.build_aptc_applied_values(family, months_array).first).to eq aptc_applied_hash_value_when_active_enrollment
      end
    
    end

    context "avalaible_aptc" do
      let(:total_aptc_available_amount_hash) {["Jan", family.active_household.latest_active_tax_household.total_aptc_available_amount]}
      let(:eligibility_determination) {EligibilityDetermination.new(determined_on: TimeKeeper.date_of_record.beginning_of_year)}
      
      it "should return a hash with value as 'total_aptc_available_amount' for household" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household).and_return tax_household
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination]
        expect(HbxAdmin.build_avalaible_aptc_values(family, months_array).first).to eq total_aptc_available_amount_hash
      end
    end

    context "max_aptc" do
      let(:sample_max_aptc) {511.78}
      let(:sample_max_aptc_hash) {["Jan",sample_max_aptc]}
      let(:eligibility_determination) {EligibilityDetermination.new(determined_on: TimeKeeper.date_of_record.beginning_of_year, max_aptc: sample_max_aptc )}

      it "should return a hash with value as 'build_max_aptc_values' for eligibility_determination" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household).and_return tax_household
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination]
        expect(HbxAdmin.build_max_aptc_values(family, months_array).first).to eq sample_max_aptc_hash
      end
    end


    context "csr_percentage" do
      let(:sample_csr_percentage_as_integer) {87}
      let(:sample_csr_percentage_as_integer_hash) {["Jan",sample_csr_percentage_as_integer]}
      let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', csr_percent_as_integer: sample_csr_percentage_as_integer, determined_on: TimeKeeper.date_of_record.beginning_of_year )}

      it "should return a hash with value as 'build_max_aptc_values' for eligibility_determination" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household).and_return tax_household
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination]
        expect(HbxAdmin.build_csr_percentage_values(family, months_array).first).to eq sample_csr_percentage_as_integer_hash
      end
    end

    context "slcsp" do
      let(:slcsp) {0}
      let(:slcsp_hash) {["Jan",slcsp]}
      let(:eligibility_determination) {EligibilityDetermination.new(determined_on: TimeKeeper.date_of_record.beginning_of_year )}
      let!(:current_hbx) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let(:hbx_profile) {double}
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let(:benefit_coverage_period) {FactoryGirl.build(:benefit_coverage_period, second_lowest_cost_silver_plan: plan)}
      let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, benefit_coverage_periods: [benefit_coverage_period] ) }
      #let(:tax_household_member1) {double(is_ia_eligible?: true, age_on_effective_date: 29)}
      #let(:tax_household_member2) {double(is_ia_eligible?: true, age_on_effective_date: 30)}

      it "should return a hash with slcsp value" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household).and_return tax_household
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination]
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        allow(tax_household).to receive(:aptc_members).and_return([])
        expect(HbxAdmin.build_slcsp_values(family, months_array).first).to eq slcsp_hash
      end
    end

  end

end
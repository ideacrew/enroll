require 'rails_helper'

RSpec.describe HbxAdmin, :type => :model do
  let(:months_array) {Date::ABBR_MONTHNAMES.compact}

  # Household
  let(:family)       { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:household) {FactoryGirl.create(:household, family: family)}
  let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
  let(:sample_max_aptc_1) {511.78}
  let(:sample_max_aptc_2) {612.33}
  let(:sample_csr_percent_1) {87}
  let(:sample_csr_percent_2) {94}
  let(:eligibility_determination_1) {EligibilityDetermination.new(determined_on: TimeKeeper.date_of_record.beginning_of_year, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1 )}
  let(:eligibility_determination_2) {EligibilityDetermination.new(determined_on: TimeKeeper.date_of_record.beginning_of_year + 4.months, max_aptc: sample_max_aptc_2, csr_percent_as_integer: sample_csr_percent_2 )}

  # Enrollments 
  let!(:hbx_with_aptc_1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days), applied_aptc_amount: 100)}
  let!(:hbx_with_aptc_2) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 210)}
  let!(:hbx_enrollments) {[hbx_with_aptc_1, hbx_with_aptc_2]}
  let(:hbx_enrollment_member_1){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month, applied_aptc_amount: 70)}
  let(:hbx_enrollment_member_2){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month, applied_aptc_amount: 30)}

  context "household_level aptc_csr data" do      
    
    before(:each) do
      allow(family).to receive(:active_household).and_return household
      allow(household).to receive(:latest_active_tax_household).and_return tax_household
      allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination_1, eligibility_determination_2]
    end

    # MAX APTC
    context "build max_aptc values" do
        let(:expected_hash_without_param_case)  { {"Jan"=>"511.78", "Feb"=>"511.78", "Mar"=>"511.78", "Apr"=>"511.78", "May"=>"612.33", "Jun"=>"612.33", 
                                                 "Jul"=>"612.33", "Aug"=>"612.33", "Sep"=>"612.33", "Oct"=>"612.33", "Nov"=>"612.33", "Dec"=>"612.33" } }
      
      let(:expected_hash_with_param_case)     { {"Jan"=>"511.78", "Feb"=>"511.78", "Mar"=>"511.78", "Apr"=>"511.78", "May"=>"612.33", "Jun"=>"612.33", 
                                                 "Jul"=>"666.00", "Aug"=>"666.00", "Sep"=>"666.00", "Oct"=>"666.00", "Nov"=>"666.00", "Dec"=>"666.00"} } 
        
      it "should return a hash that reflects max_aptc change on a montly basis based on the determined_on date of eligibility determinations - without max_aptc param" do
        expect(HbxAdmin.build_max_aptc_values(family, nil)).to eq expected_hash_without_param_case
      end

      # This 'change in param' case is for the AJAX call where the latest max_aptc is not read from the latest ED from the database but read from a user input - transient"
      it "should return a hash that reflects max_aptc change on a montly basis based on the determined_on date of eligibility determinations - with max_aptc param" do
        expect(HbxAdmin.build_max_aptc_values(family, 666)).to eq expected_hash_with_param_case
      end
    end

    # CSR PERCENT AS INTEGER 
    context "build csr_percentage values" do

      let(:expected_hash_without_param_case)  { {"Jan"=>87, "Feb"=>87, "Mar"=>87, "Apr"=>87, "May"=>94, "Jun"=>94, "Jul"=>94, "Aug"=>94, "Sep"=>94, "Oct"=>94, "Nov"=>94, "Dec"=>94} }
      let(:expected_hash_with_param_case)     { {"Jan"=>87, "Feb"=>87, "Mar"=>87, "Apr"=>87, "May"=>94, "Jun"=>94, "Jul"=>100, "Aug"=>100, "Sep"=>100, "Oct"=>100, "Nov"=>100, "Dec"=>100} } 
        
      it "should return a hash that reflects csr_percent change on a montly basis based on the determined_on date of eligibility determinations - without csr_percent param" do
        expect(HbxAdmin.build_csr_percentage_values(family, nil)).to eq expected_hash_without_param_case
      end

      it "should return a hash that reflects csr_percent change on a montly basis based on the determined_on date of eligibility determinations - with csr_percent param" do
        expect(HbxAdmin.build_csr_percentage_values(family, 100)).to eq expected_hash_with_param_case
      end
    end

  end


  context "enrollment_level applied_aptc data" do
    
    let (:expected_applied_hash) { { hbx_with_aptc_1.hbx_enrollment_members.first.person.id.to_s => aptc_applied_vals } }
    let (:expected_total_premium) { { hbx_enrollments[0].id.to_s => total_premium_hbx1 , hbx_enrollments[1].id.to_s => total_premium_hbx2} }
    let (:aptc_ratio_hash) { {hbx_enrollment_member_1.applicant_id.to_s => 1.00 } }
    let (:total_premium_hbx1) {870.00 }
    let (:total_premium_hbx2) {980.00 } 
    
    before(:each) do
      allow(family).to receive(:active_household).and_return household
      allow(household).to receive(:latest_active_tax_household).and_return tax_household
      allow(tax_household).to receive(:aptc_ratio_by_member).and_return aptc_ratio_hash
      allow(household).to receive(:hbx_enrollments).and_return hbx_enrollments
      hbx_enrollment = hbx_enrollments[0]
      allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return [hbx_enrollment_member_1, hbx_enrollment_member_2]
      allow(hbx_enrollment).to receive(:total_premium).and_return total_premium_hbx1
      hbx_enrollment = hbx_enrollments[1]
      allow(hbx_enrollment).to receive(:total_premium).and_return total_premium_hbx2
      hbx_enrollment_member = hbx_enrollment_member_1
      allow(hbx_enrollment_member).to receive(:person).and_return family.person
      hbx_enrollment_member = hbx_enrollment_member_2
      allow(hbx_enrollment_member).to receive(:person).and_return family.person
      allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination_1, eligibility_determination_2]
    end
    
    let (:aptc_applied_hash) { Hash.new }
    let (:aptc_applied_vals) { {"Jan"=>"120.00", "Feb"=>"120.00", "Mar"=>"112.00", "Apr"=>"158.00", "May"=>"158.00", "Jun"=>"158.00", 
                                                 "Jul"=>"158.00", "Aug"=>"158.00", "Sep"=>"158.00", "Oct"=>"158.00", "Nov"=>"158.00", "Dec"=>"158.00" }}
    
    it "build_aptc_applied_per_member_values_for_enrollment" do
      expect(HbxAdmin.build_aptc_applied_per_member_values_for_enrollment(family, hbx_with_aptc_1, aptc_applied_vals, nil)).to eq expected_applied_hash
    end
    
    
    it "should return plan_premium values for different enrollments" do
      expect(HbxAdmin.build_plan_premium_hash_for_enrollments(hbx_enrollments)).to eq expected_total_premium
    end

  end

end
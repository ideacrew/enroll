require 'rails_helper'

RSpec.describe Services::EligibilityService, type: :model do

  context "Assisted enrollment" do
    let!(:hbx_profile) {FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:renewal_calender_date) {HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on}
    let!(:renewal_calender_year) {renewal_calender_date.year}

    let!(:family_assisted) {FactoryGirl.create(:individual_market_family)}
    let!(:tax_household1) {FactoryGirl.create(:tax_household, effective_starting_on: renewal_calender_date,
                                              effective_ending_on: nil, household: family_assisted.active_household)}
    let!(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household1)}
    let!(:tax_household_member1) {tax_household1.tax_household_members.create(applicant_id: family_assisted.family_members.first.id,
                                                                              is_ia_eligible: true)}
    let!(:enrollment_assisted) {FactoryGirl.create(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                                                   applied_aptc_amount: 110,
                                                   consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                                                   household: family_assisted.active_household,
                                                   enrollment_members: [family_assisted.family_members.first],
                                                   plan: active_csr_87_plan)}

    let!(:renewal_enrollment_assisted) {FactoryGirl.build(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                                                   consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                                                          effective_on: renewal_calender_date,
                                                   household: family_assisted.active_household,
                                                   enrollment_members: [family_assisted.family_members.first],
                                                   plan: renewal_csr_87_plan)}

    let!(:active_csr_87_plan) {FactoryGirl.create(:active_csr_87_plan, renewal_plan: renewal_csr_87_plan)}
    let!(:renewal_csr_87_plan) {FactoryGirl.create(:renewal_csr_87_plan)}
    let!(:update_renewal_csr_87_plan) {renewal_csr_87_plan.update_attributes!(hios_id: active_csr_87_plan.hios_id,
                                                                              hios_base_id: active_csr_87_plan.hios_base_id)}

    subject {
      eligibility_service = Services::EligibilityService.new
      eligibility_service.enrollment = renewal_enrollment_assisted
      eligibility_service.aptc_values = {applied_percentage: 87,
                                         applied_aptc: 150,
                                         csr_amt: 87,
                                         max_aptc: 200}
      eligibility_service.family = family_assisted
      eligibility_service

    }

    before do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(renewal_calender_date.beginning_of_year)}.update_attributes!(slcsp_id: renewal_csr_87_plan.id)
      hbx_profile.reload
      family_assisted.active_household.reload
      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
    end

    it "should append APTC values" do
      renewel_enrollment = subject.apply_aptc
      expect(renewel_enrollment.applied_aptc_amount.to_f).to eq (renewel_enrollment.total_premium * renewel_enrollment.plan.ehb).round(2)
    end

    it "should get min on given applied, ehb premium and available aptc" do
      expect(subject.calculate_applied_aptc).to eq 45.7378
    end

    it "should calculate ehb premium value" do
      expect(subject.calculate_ehb_premium).to eq 45.7378
    end

    it "should calculate available APTC value" do
      expect(subject.calculate_available_aptc).to eq 225.13
    end

    it "should get latest THH for given year" do
      expect(subject.active_thh_for_enrollment_year).to eq tax_household1
    end
  end
end

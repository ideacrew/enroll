require 'rails_helper'
require "#{Rails.root}/spec/shared_contexts/enrollment.rb"

RSpec.describe Services::EligibilityService, type: :model do

  context "Assisted enrollment" do
    include_context "setup families enrollments"

    let!(:renewal_enrollment_assisted) {FactoryGirl.build(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                                                          consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                                                          effective_on: renewal_calender_date,
                                                          household: family_assisted.active_household,
                                                          enrollment_members: [family_assisted.family_members.first],
                                                          plan: renewal_csr_87_plan)}

    subject {
      eligibility_service = Services::EligibilityService.new(renewal_enrollment_assisted)
      eligibility_service.process
      eligibility_service
    }

    let(:aptc_values) {{applied_percentage: 87,
                         applied_aptc: 150,
                         csr_amt: 87,
                         max_aptc: 200}}

    before do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(renewal_calender_date.beginning_of_year)}.update_attributes!(slcsp_id: renewal_csr_87_plan.id)
      hbx_profile.reload
      family_assisted.active_household.reload
      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
    end

    it "should process and return available aptc/csr" do
      expect(subject.available_aptc).not_to eq nil
    end

    it "should append APTC values" do
      renewel_enrollment = subject.assign(aptc_values)
      expect(renewel_enrollment.applied_aptc_amount.to_f).to eq (renewel_enrollment.total_premium * renewel_enrollment.plan.ehb).round(2)
    end

    it "should get min on given applied, ehb premium and available aptc" do
      expect(subject.calculate_applied_aptc(aptc_values)).to eq 45.7378
    end

    it "should return tax_household members" do
      expect(subject.find_tax_household_members).to eq tax_household.tax_household_members
    end
  end
end

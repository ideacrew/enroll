require 'rails_helper'

describe Household, "given a coverage household with a dependent" do
  let(:family_member) { FamilyMember.new }
  let(:coverage_household_member) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }
  let(:coverage_household) { CoverageHousehold.new(:coverage_household_members => [coverage_household_member]) }

  subject { Household.new(:coverage_households => [coverage_household]) }

  it "should remove the dependent from the coverage households when removing them from the household" do
    expect(coverage_household).to receive(:remove_family_member).with(family_member)
    subject.remove_family_member(family_member)
  end

  it "should not have any enrolled hbx enrollments" do
    expect(subject.enrolled_hbx_enrollments).to eq []
  end

  context "new_hbx_enrollment_from" do 
    let(:consumer_role) {FactoryGirl.create(:consumer_role)}
    let(:person) { double(primary_family: family)}
    let(:family) { double }
    let(:benefit_package) {FactoryGirl.create(:benefit_package)}
    let(:hbx) {double(benefit_sponsorship: double(earliest_effective_date: TimeKeeper.date_of_record, current_benefit_period: bcp))}
    let(:bcp) {double(earliest_effective_date: TimeKeeper.date_of_record)}
    let(:coverage_household) {CoverageHousehold.new}
    let(:household) {Household.new}

    before do 
      allow(HbxProfile).to receive(:current_hbx).and_return(hbx)
      allow(consumer_role).to receive(:person).and_return(person)
      allow(family).to receive(:is_under_special_enrollment_period?).and_return false
      allow(household).to receive(:family).and_return(family)
      allow(coverage_household).to receive(:household).and_return(household)
    end

    it "should build hbx enrollment" do 
      subject.new_hbx_enrollment_from(
        consumer_role: consumer_role,
        coverage_household: coverage_household,
        benefit_package: benefit_package, 
        qle: false
      )
    end
  end
  
  context "latest_active_tax_household_with_year" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryGirl.create(:household, family: family)}
    let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
    let(:tax_household2) {FactoryGirl.create(:tax_household, household: household)}
    let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}

    it "return correct tax_household" do
      household.tax_households << tax_household
      expect(household.latest_active_tax_household_with_year(hbx1.effective_on.year)).to eq tax_household

    end

    it "return nil while current year is not empty" do
      household.tax_households << tax_household2
      expect(household.latest_active_tax_household_with_year(hbx1.effective_on.year)).to be_nil
    end

    it "return nil for not the same year" do
      household.tax_households << tax_household
      expect(household.latest_active_tax_household_with_year((hbx1.effective_on + 1.year).year)).to be_nil
    end

  end

  context "current_year_hbx_enrollments" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
    let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: false)}
    let!(:hbx3) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_terminated', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}
    let!(:hbx4) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: true)}

    it "should return right hbx_enrollments" do
      household.reload
      expect(household.hbx_enrollments.count).to eq 4
      expect(household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)).to eq [hbx1]
    end
  end

  it "ImmediateFamily should have stepchild" do
    expect(Household::ImmediateFamily.include?('stepchild')).to eq true
  end

  # context "with an enrolled hbx enrollment" do
  #   let(:mock_hbx_enrollment) { instance_double(HbxEnrollment) }
  #   let(:hbx_enrollments) { [mock_hbx_enrollment] }
  #   before do
  #     allow(HbxEnrollment).to receive(:covered).with(hbx_enrollments).and_return(hbx_enrollments)
  #     allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
  #   end

  #   it "should return the enrolled hbx enrollment in an array" do
  #     expect(subject.enrolled_hbx_enrollments).to eq hbx_enrollments
  #   end
  # end
end

require 'rails_helper'

RSpec.describe Enrollments::IndividualMarket::FamilyEnrollmentRenewal, type: :model do

  let(:current_benefit_coverage_period) { OpenStruct.new(start_on: Date.new(2017,1,1), end_on: Date.new(2017,12,31)) }
  let(:renewal_benefit_coverage_period) { OpenStruct.new(start_on: Date.new(2018,1,1), end_on: Date.new(2018,12,31)) }

  let(:aptc_values) {{}}
  let(:assisted) { nil }

  let!(:family) {
    primary = FactoryGirl.create(:person, :with_consumer_role, dob: primary_dob)
    FactoryGirl.create(:family, :with_primary_family_member, :person => primary)
  }

  let!(:spouse_rec) { 
    FactoryGirl.create(:person, dob: spouse_dob)
  }

  let!(:spouse) { 
    FactoryGirl.create(:family_member, person: spouse_rec, family: family)
  }

  let!(:child1) { 
    child = FactoryGirl.create(:person, dob: child1_dob)
    FactoryGirl.create(:family_member, person: child, family: family)
  }

  let!(:child2) { 
    child = FactoryGirl.create(:person, dob: child2_dob)
    FactoryGirl.create(:family_member, person: child, family: family)
  }

  let(:primary_dob){ TimeKeeper.date_of_record.next_month - 57.years }
  let(:spouse_dob) { TimeKeeper.date_of_record.next_month - 55.years }
  let(:child1_dob) { TimeKeeper.date_of_record.next_month - 26.years }
  let(:child2_dob) { TimeKeeper.date_of_record.next_month - 20.years }

  let!(:enrollment) {
    FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
      enrollment_members: enrollment_members,
      household: family.active_household,
      coverage_kind: coverage_kind,
      effective_on: current_benefit_coverage_period.start_on,
      kind: "individual",
      plan_id: current_plan.id,
      aasm_state: 'coverage_selected'
    )
  }
  let(:enrollment_members) { family.family_members }

  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:coverage_kind) { 'health' }
  let(:current_plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01", csr_variant_id: "01") }

  subject { 
    enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
    enrollment_renewal.enrollment = enrollment
    enrollment_renewal.assisted = assisted
    enrollment_renewal.aptc_values = aptc_values
    enrollment_renewal.renewal_benefit_coverage_period = renewal_benefit_coverage_period
    enrollment_renewal.current_benefit_coverage_period = current_benefit_coverage_period
    enrollment_renewal
  }

  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(calender_year, 11, 1))
  end

  describe ".clone_enrollment_members" do

    before do
      allow(child1).to receive(:relationship).and_return('child')
      allow(child2).to receive(:relationship).and_return('child')
    end

    context "When a child is aged off" do
      it "should not include child" do
        applicant_ids = subject.clone_enrollment_members.collect{|m| m.applicant_id}

        expect(applicant_ids).to include(family.primary_applicant.id)
        expect(applicant_ids).to include(spouse.id)
        expect(applicant_ids).not_to include(child1.id)
        expect(applicant_ids).to include(child2.id)
      end
    end

    # Don't we need this for all the dependents
    # Are we using is_disabled flag in the system
    context "When a child person record is disabled" do
      let!(:spouse_rec) { 
        FactoryGirl.create(:person, dob: spouse_dob, is_disabled: true)
      }

      it "should not include child person record" do
        applicant_ids = subject.clone_enrollment_members.collect{|m| m.applicant_id}
        expect(applicant_ids).not_to include(spouse.id)
      end
    end
  end

  describe ".renewal_plan" do
    context "When consumer covered under catastrophic plan" do

      let!(:cat_age_off_plan) { FactoryGirl.create(:plan, market: 'individual', metal_level: 'silver', active_year: TimeKeeper.date_of_record.year + 1, hios_id: "11111111122300-01", csr_variant_id: "01") }
      let!(:renewal_plan) { FactoryGirl.create(:plan, market: 'individual', metal_level: 'catastrophic', active_year: TimeKeeper.date_of_record.year + 1, hios_id: "11111111122302-01", csr_variant_id: "01") }
      let!(:current_plan) { FactoryGirl.create(:plan, market: 'individual', metal_level: 'catastrophic', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, cat_age_off_renewal_plan_id: cat_age_off_plan.id) }

      let(:enrollment_members) { [child1, child2] }

      context "When one of the covered individuals aged off(30 years)" do
        let(:child1_dob) { TimeKeeper.date_of_record.next_month - 30.years }

        it "should return catastrophic aged off plan" do
          expect(subject.renewal_plan).to eq cat_age_off_plan
        end
      end

      context "When all the covered individuals under 30" do
        let(:child1_dob) { TimeKeeper.date_of_record.next_month - 25.years }

        it "should return renewal plan" do
          expect(subject.renewal_plan).to eq renewal_plan
        end 
      end
    end
  end

  describe ".assisted_renewal_plan" do

    context "When individual eligible for csr" do 
      it "should return csr variant plan" do 
      end
    end

    context "When its not a csr" do
      it "should return renewal plan" do 
      end
    end
  end

  describe ".clone_enrollment" do
    context "For QHP enrollment" do
      it "should set enrollment atrributes" do 
      end 
    end

    context "Assisted enrollment" do
      it "should append APTC values" do
      end 
    end
  end
end
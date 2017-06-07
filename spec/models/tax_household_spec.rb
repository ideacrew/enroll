require 'rails_helper'

RSpec.describe TaxHousehold, type: :model do
  let(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }



# describe TaxHousehold do
=begin
  describe "validate associations" do
#	  it { should have_and_belong_to_many  :people }
#	  it { should embed_many :special_enrollment_periods }
	  it { should embed_many :eligibilities }
=end

  it "should have no people" do
    expect(subject.people).to be_empty
  end

=begin

  it "max_aptc and csr values returned are from the most recent eligibility record" do
  	hh = Household.new(
  			eligibilities: [
  				Eligibility.new({date_determined: Date.today - 100, max_aptc: 101.05, csr_percent: 1.0}),
  				Eligibility.new({date_determined: Date.today - 80, max_aptc: 181.05, csr_percent: 0.80}),
  				Eligibility.new({date_determined: Date.today, max_aptc: 287.95, csr_percent: 0.73}),
  				Eligibility.new({date_determined: Date.today - 50, max_aptc: 101.05, csr_percent: 0.50})
  			]
  		)

  	expect(hh.max_aptc).to eq(287.95)
  	expect(hh.csr_percent).to eq(0.73)
  end
  it "returns list of SEPs for specified day and single 'current_sep'" do
  	hh = Household.new(
  			special_enrollment_periods: [
  				SpecialEnrollmentPeriod.new({reason: "marriage", start_date: Date.today - 120, end_date: Date.today - 90}),
  				SpecialEnrollmentPeriod.new({reason: "retirement", start_date: Date.today - 10, end_date: Date.today + 20}),
  				SpecialEnrollmentPeriod.new({reason: "birth", start_date: Date.today - 90, end_date: Date.today - 60}),
  				SpecialEnrollmentPeriod.new({reason: "location_change", start_date: Date.today - 260, end_date: Date.today - 230}),
  				SpecialEnrollmentPeriod.new({reason: "employment_termination", start_date: Date.today - 180, end_date: Date.today - 150})
  			]
  		)

		past_day = hh.active_seps(Date.today - 500)
  	expect(past_day.count).to eq(0)

		wedding_day = hh.active_seps(Date.today - 120)
  	expect(wedding_day.count).to eq(1)
  	expect(wedding_day.first.reason).to eq("marriage")
  	expect(wedding_day.first.start_date).to eq(Date.today - 120)

  	expect(hh.current_sep.reason).to eq("retirement")
  	expect(hh.current_sep.start_date).to eq(Date.today - 10)
  end

  describe "new SEP effects on enrollment state:" do

		it "should initialize to closed_enrollment state" do
			hh = Household.new
			expect(hh.closed_enrollment?).to eq(true)
		end

		it "should transition to open_enrollment_period from any other enrollment state (including open_enrollment_period)" do
			hh = Household.new
			expect(hh.closed_enrollment?).to eq(true)
			hh.open_enrollment
			expect(hh.open_enrollment_period?).to eq(true)
			hh.open_enrollment
			expect(hh.open_enrollment_period?).to eq(true)
			hh.special_enrollment
			expect(hh.special_enrollment_period?).to eq(true)
			hh.open_enrollment
			expect(hh.open_enrollment_period?).to eq(true)
		end

		it "not affect state when system date is outside new SEP date range" do
			hh = Household.new
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "marriage", start_date: Date.today - 120, end_date: Date.today - 90})
			expect(hh.closed_enrollment?).to eq(true)

			hh.special_enrollment
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "location_change", start_date: Date.today - 90, end_date: Date.today - 60})
			expect(hh.special_enrollment_period?).to eq(true)
  	end

  	it "set state to special_enrollment_period when system date is within SEP date range" do
			hh = Household.new(rel: "subscriber")
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "birth", start_date: Date.today - 5, end_date: Date.today + 25})
			hh.save!

			expect(hh.special_enrollment_period?).to eq(true)
			expect(hh.current_sep.reason).to eq("birth")
  	end

  	it "change state from open_enrollment_period to special_enrollment_period when end_date is later" do
			hh = Household.new(rel: "spouse")
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "open_enrollment_start", start_date: Date.today - 30, end_date: Date.today + 5})
			hh.save!
			expect(hh.open_enrollment_period?).to eq(true)

			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "adoption", start_date: Date.today - 15, end_date: Date.today + 15})
			expect(hh.special_enrollment_period?).to eq(true)
  	end

  	it "do not change state from open_enrollment_period to special_enrollment_period when end_date is prior" do
			hh = Household.new(rel: "spouse")
			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "open_enrollment_start", start_date: Date.today - 30, end_date: Date.today + 5})
			hh.save!
			expect(hh.open_enrollment_period?).to eq(true)

			hh.special_enrollment_periods << SpecialEnrollmentPeriod.new({reason: "adoption", start_date: Date.today - 29, end_date: Date.today + 1})
			expect(hh.open_enrollment_period?).to eq(true)
  	end

		it "manually force active enrollment periods to close" do
		end

		it "change Household state when System date enters or exits current_sep range" do
		end
  end
=end

  describe "single tax household" do
    context "aptc_ratio_by_member" do
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let(:current_hbx) {double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period]))}
      let(:benefit_coverage_period) {double(contains?:true, second_lowest_cost_silver_plan: plan)}
      let(:application) { FactoryGirl.create(:application, family: family) }
      let(:tax_household) { FactoryGirl.create(:tax_household, effective_starting_on: TimeKeeper.date_of_record, application: application) }
      let(:family_member1) { FactoryGirl.create(:family_member, family: family) }
      let(:family_member2) { FactoryGirl.create(:family_member, family: family) }
      let(:applicant1) { FactoryGirl.create(:applicant, application: application, tax_household_id: tax_household.id, family_member_id: family_member1.id) }
      let(:applicant2) { FactoryGirl.create(:applicant, application: application, tax_household_id: tax_household.id, family_member_id: family_member2.id) }

      it "can return ratio hash" do
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
        allow(plan).to receive(:premium_for).and_return(110)
        allow(tax_household).to receive(:aptc_members).and_return([applicant1, applicant2])
        expect(tax_household.aptc_ratio_by_member.class).to eq Hash
        result = {family_member1.id.to_s =>0.5, family_member2.id.to_s =>0.5}
        expect(tax_household.aptc_ratio_by_member).to eq result
      end
    end

    context "aptc_available_amount_by_member" do
      let(:aptc_ratio_by_member) { {'member1'=>0.6, 'member2'=>0.4} }
      let(:hbx_member1) { double(applicant_id: 'member1', applied_aptc_amount: 20) }
      let(:hbx_member2) { double(applicant_id: 'member2', applied_aptc_amount: 10) }
      let(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let(:household) { double }
      let(:application) { double(family: family) }

      it "can return result" do
        tax_household = TaxHousehold.new()
        allow(tax_household).to receive(:family).and_return family
        allow(family).to receive(:active_household).and_return household
        allow(tax_household).to receive(:application).and_return application
        allow(tax_household).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member
        allow(tax_household).to receive(:current_max_aptc).and_return 100
        allow(tax_household).to receive(:effective_starting_on).and_return TimeKeeper.date_of_record
        allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
        expect(tax_household.aptc_available_amount_by_member.class).to eq Hash
        result = {'member1'=>40, 'member2'=>30}
        expect(tax_household.aptc_available_amount_by_member).to eq result
      end
    end

    context "aptc_available_amount_for_enrollment" do
      let(:aptc_available_amount_by_member) { {'member1'=>60, 'member2'=>40} }
      let(:hbx_member1) { double(applicant_id: 'member1') }
      let(:hbx_member2) { double(applicant_id: 'member2') }
      let(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let(:household) { double }
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let(:decorated_plan) {double}

      before :each do
        @tax_household = TaxHousehold.new()
        allow(plan).to receive(:ehb).and_return 0.9
        allow(@tax_household).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member
        allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 100
        allow(UnassistedPlanCostDecorator).to receive(:new).and_return(decorated_plan)
        allow(decorated_plan).to receive(:premium_for).and_return(100)
        allow(household).to receive(:hbx_enrollments_with_aptc_by_date).and_return([hbx_enrollment])
      end

      it "can return result when plan is individual" do
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1'=>30, 'member2'=>20}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end

      it "when ehb_premium > aptc_amount" do
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1'=>9, 'member2'=>9}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end

      it "can return result when plan is dental" do
        allow(plan).to receive(:coverage_kind).and_return 'dental'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1'=>0, 'member2'=>0}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end

      it "can return result when total_aptc_available_amount is 0" do
        allow(@tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50).class).to eq Hash
        result = {'member1'=>0, 'member2'=>0}
        expect(@tax_household.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 50)).to eq result
      end
    end

    context "current_max_aptc" do
      before :each do
        @tax_household = TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record)
      end

      it "return max aptc when in the same year" do
        allow(@tax_household).to receive(:preferred_eligibility_determination).and_return(double(determined_on: TimeKeeper.date_of_record, max_aptc: 100))
        expect(@tax_household.current_max_aptc).to eq 100
      end

      it "return 0 when not in the same year" do
        allow(@tax_household).to receive(:preferred_eligibility_determination).and_return(double(determined_on: TimeKeeper.date_of_record + 1.year, max_aptc: 0))
        expect(@tax_household.current_max_aptc).to eq 0
      end
    end

    context "current_csr_eligibility_kind" do
      let(:application) {FactoryGirl.create(:application, family: family)}
      let(:tax_household) {FactoryGirl.create(:tax_household, application: application)}
      let(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, csr_eligibility_kind: "csr_87", determined_on: TimeKeeper.date_of_record, application: application, tax_household_id: tax_household.id)}


      it "should equal to the csr_eligibility_kind of preferred_eligibility_determination" do
        eligibility_determination.save!
        expect(application.current_csr_eligibility_kind(tax_household.id)).to eq eligibility_determination.csr_eligibility_kind
      end

      it "should return the right eligibility_determination based on the tax_household_id" do
        eligibility_determination.save!
        ed = application.eligibility_determinations.where(tax_household_id: tax_household.id).first
        expect(ed).to eq eligibility_determination
      end
    end
  end

  describe "multi tax households" do
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:family_member1) { family.primary_applicant }
    let!(:family_member2) { FactoryGirl.create(:family_member, family: family) }
    let!(:family_member3) { FactoryGirl.create(:family_member, family: family) }
    let!(:family_member4) { FactoryGirl.create(:family_member, family: family) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:tax_household1) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
    let!(:tax_household2) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record)}
    let!(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household1.id, source: "Curam", csr_eligibility_kind: "csr_87", determined_on: TimeKeeper.date_of_record, max_aptc: 200.00)}
    let!(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household1.id, source: "Haven", csr_eligibility_kind: "csr_94", determined_on: TimeKeeper.date_of_record, max_aptc: 200.00)}
    let!(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household2.id, source: "Curam", csr_eligibility_kind: "csr_73", determined_on: TimeKeeper.date_of_record, max_aptc: 200.00)}
    let!(:eligibility_determination4) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household2.id, source: "Haven", csr_eligibility_kind: "csr_100", determined_on: TimeKeeper.date_of_record, max_aptc: 200.00)}
    let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
    let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id) }
    let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member3.id) }
    let!(:applicant4) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member4.id) }

    context "aptc_ratio_by_member" do
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let(:current_hbx) {double(benefit_sponsorship: double(benefit_coverage_periods: [benefit_coverage_period]))}
      let(:benefit_coverage_period) {double(contains?:true, second_lowest_cost_silver_plan: plan)}

      it "can return ratio hash" do
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
        allow(plan).to receive(:premium_for).and_return(110)
        allow(tax_household1).to receive(:aptc_members).and_return([applicant1, applicant2])
        allow(tax_household2).to receive(:aptc_members).and_return([applicant3, applicant4])
        expect(tax_household1.aptc_ratio_by_member.class).to eq Hash
        result1 = {family_member1.id.to_s =>0.5, family_member2.id.to_s =>0.5}
        expect(tax_household1.aptc_ratio_by_member).to eq result1
        expect(tax_household2.aptc_ratio_by_member.class).to eq Hash
        result2 = {family_member3.id.to_s =>0.5, family_member4.id.to_s =>0.5}
        expect(tax_household2.aptc_ratio_by_member).to eq result2
      end
    end

    context "aptc_available_amount_by_member" do
      let(:aptc_ratio_by_member1) { {family_member1.id.to_s =>0.5, family_member2.id.to_s =>0.5} }
      let(:aptc_ratio_by_member2) { {family_member3.id.to_s =>0.5, family_member4.id.to_s =>0.5} }
      let!(:hbx_member1) { double(applicant_id: family_member1.id, applied_aptc_amount: 70) }
      let!(:hbx_member2) { double(applicant_id: family_member3.id, applied_aptc_amount: 50) }
      let!(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let!(:household) { double }

      it "can return result" do
        allow(tax_household1).to receive(:family).and_return family
        allow(family).to receive(:active_household).and_return household
        allow(tax_household1).to receive(:application).and_return application
        allow(tax_household1).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member1
        allow(tax_household1).to receive(:effective_starting_on).and_return TimeKeeper.date_of_record

        allow(tax_household2).to receive(:family).and_return family
        allow(tax_household2).to receive(:application).and_return application
        allow(tax_household2).to receive(:aptc_ratio_by_member).and_return aptc_ratio_by_member2
        allow(tax_household2).to receive(:effective_starting_on).and_return TimeKeeper.date_of_record

        allow(household).to receive(:hbx_enrollments_with_aptc_by_year).and_return([hbx_enrollment])
        expect(tax_household1.aptc_available_amount_by_member.class).to eq Hash
        result1 = {family_member1.id.to_s=>30.0, family_member2.id.to_s=>100.0}
        expect(tax_household1.aptc_available_amount_by_member).to eq result1
        expect(tax_household2.aptc_available_amount_by_member.class).to eq Hash
        result2 = {family_member3.id.to_s=>50.0, family_member4.id.to_s=>100.0}
        expect(tax_household2.aptc_available_amount_by_member).to eq result2
      end
    end

    context "aptc_available_amount_for_enrollment" do
      let!(:aptc_available_amount_by_member1) { {family_member1.id.to_s=>100.0, family_member2.id.to_s=>100.0} }
      let!(:aptc_available_amount_by_member2) { {family_member3.id.to_s=>100.0, family_member4.id.to_s=>100.0} }
      let!(:hbx_member1) { double(applicant_id: family_member1.id) }
      let!(:hbx_member2) { double(applicant_id: family_member3.id) }
      let!(:hbx_enrollment) { double(applied_aptc_amount: 30, hbx_enrollment_members: [hbx_member1, hbx_member2]) }
      let!(:household) { double }
      let!(:plan) {FactoryGirl.build(:plan, :with_premium_tables)}
      let!(:decorated_plan) {double}

      before :each do
        allow(plan).to receive(:ehb).and_return 0.9
        allow(tax_household1).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member1
        allow(tax_household1).to receive(:total_aptc_available_amount_for_enrollment).and_return tax_household1.current_max_aptc
        allow(tax_household2).to receive(:aptc_available_amount_by_member).and_return aptc_available_amount_by_member2
        allow(tax_household2).to receive(:total_aptc_available_amount_for_enrollment).and_return tax_household2.current_max_aptc
        allow(UnassistedPlanCostDecorator).to receive(:new).and_return(decorated_plan)
        allow(decorated_plan).to receive(:premium_for).and_return(100)
        allow(household).to receive(:hbx_enrollments_with_aptc_by_date).and_return([hbx_enrollment])
      end

      it "can return result when plan is individual" do
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result1 = {family_member1.id.to_s=>50.0, family_member3.id.to_s=>0.0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result1
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result2 = {family_member1.id.to_s=>0.0, family_member3.id.to_s=>50.0}
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result2
      end

      it "when ehb_premium > aptc_amount" do
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result1 = {family_member1.id.to_s=>9, family_member3.id.to_s=>0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result1
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result2 = {family_member1.id.to_s=>0, family_member3.id.to_s=>9}
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result2
      end

      it "can return result when plan is dental" do
        allow(plan).to receive(:coverage_kind).and_return 'dental'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result = {family_member1.id.to_s=>0, family_member3.id.to_s=>0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
      end

      it "can return result when total_aptc_available_amount is 0" do
        allow(tax_household1).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
        allow(tax_household2).to receive(:total_aptc_available_amount_for_enrollment).and_return 0
        allow(decorated_plan).to receive(:premium_for).and_return(10)
        allow(plan).to receive(:coverage_kind).and_return 'individual'
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        result = {family_member1.id.to_s=>0, family_member3.id.to_s=>0}
        expect(tax_household1.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100).class).to eq Hash
        expect(tax_household2.aptc_available_amount_for_enrollment(hbx_enrollment, plan, 100)).to eq result
      end
    end

    context "current_max_aptc" do
      it "return max aptc when in the same year" do
        expect(tax_household1.current_max_aptc).to eq 200
        expect(tax_household2.current_max_aptc).to eq 200
      end

      it "return 0 when not in the same year" do
        allow(tax_household1).to receive(:preferred_eligibility_determination).and_return(double(determined_on: TimeKeeper.date_of_record + 1.year, max_aptc: 0))
        allow(tax_household2).to receive(:preferred_eligibility_determination).and_return(double(determined_on: TimeKeeper.date_of_record + 1.year, max_aptc: 0))
        expect(tax_household1.current_max_aptc).to eq 0
        expect(tax_household2.current_max_aptc).to eq 0
      end
    end

    context "current_csr_eligibility_kind" do

      it "should equal to the csr_eligibility_kind of preferred_eligibility_determination" do
        expect(application.current_csr_eligibility_kind(tax_household1.id)).to eq tax_household1.preferred_eligibility_determination.csr_eligibility_kind
        expect(application.current_csr_eligibility_kind(tax_household2.id)).to eq tax_household2.preferred_eligibility_determination.csr_eligibility_kind
      end

      it "should return the right eligibility_determination based on the tax_household_id" do
        ed1 = application.eligibility_determinations.where(tax_household_id: tax_household1.id).first
        expect(ed1).to eq eligibility_determination1
        ed2 = application.eligibility_determinations.where(tax_household_id: tax_household2.id).first
        expect(ed2).to eq eligibility_determination3
      end
    end
  end
end

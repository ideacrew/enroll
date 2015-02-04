require 'rails_helper'

describe TaxHousehold do
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

end

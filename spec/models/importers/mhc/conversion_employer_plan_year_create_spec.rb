require "rails_helper"

describe ::Importers::Mhc::ConversionEmployerPlanYearCreate, dbclean: :after_each do

  let!(:record_attrs) {
    {
      :action=>"Add",
      :fein=>"512121312",
      :enrolled_employee_count=>"1",
      :new_coverage_policy=>"First of the month following 30 days",
      :coverage_start=>"01/01/2018",
      :carrier=>"bmc healthnet plan",
      :plan_selection=>"Sole Source",
      :single_plan_hios_id=>"82569MA0200001-01",
      :employee_only_rt_contribution=>"100",
      :employee_only_rt_premium=>"450",
      :employee_and_spouse_rt_offered=>"True",
      :employee_and_spouse_rt_contribution=>"76",
      :employee_and_spouse_rt_premium=>"810",
      :employee_and_one_or_more_dependents_rt_offered=>"False",
      :employee_and_one_or_more_dependents_rt_contribution=>"75",
      :employee_and_one_or_more_dependents_rt_premium=>"820",
      :family_rt_offered=>"False",
      :family_rt_contribution=>"70",
      :family_rt_premium=>"850"
    }
  }

  let!(:registered_on) { TimeKeeper.date_of_record.beginning_of_month }
  let!(:default_plan_year_start) { (registered_on + 3.months).prev_year }

  let!(:fein) { record_attrs[:fein] }

  let!(:carrier_profile) {FactoryGirl.create(:carrier_profile, with_service_areas: 0, issuer_hios_ids: ['11111'], abbrev: 'NHP', offers_sole_source: true)}
  let!(:carrier_one_service_area) { create(:carrier_service_area, service_area_zipcode: '01862', issuer_hios_id: carrier_profile.issuer_hios_ids.first) }
  let!(:plan) { FactoryGirl.create(:plan, carrier_profile: carrier_profile, active_year: default_plan_year_start.year, service_area_id: carrier_one_service_area.service_area_id, hios_id: record_attrs[:single_plan_hios_id]) }

  subject { Importers::Mhc::ConversionEmployerPlanYearCreate.new(record_attrs.merge({:default_plan_year_start => default_plan_year_start})) }
  
  let(:out_stream) { StringIO.new }
  let(:file_name) { File.join(Rails.root, "spec", "test_data", "conversion_employers", "Employer Full Launch Template_TEST_20171020.xlsx") }

  before :each do
    allow(CarrierServiceArea).to receive(:service_areas_for).and_return([carrier_one_service_area])
    importer = Importers::Mhc::ConversionEmployerSet.new(file_name, out_stream, registered_on.strftime('%Y-%m-%d'))
    # allow(ConversionEmployerCreate).to receive(:new).with(record_attrs.merge({:registered_on => registered_on.strftime('%Y-%m-%d') }))
    importer.import!
    out_stream.rewind
  end

  context "provided with employer date" do
    before do
      @employer = EmployerProfile.find_by_fein(fein)
      # need to understand how service area been being mapped.
      # allow(CarrierProfile).to receive(:carrier_profile_service_area_pairs_for).with(@employer).and_return([carrier_profile.id, @employer.service_areas.first.service_area_id])
    end

    it "should create plan year" do
      expect(@employer.present?).to be_truthy
      expect(@employer.plan_years.empty?).to be_truthy

      subject.save
      employer_profile = @employer.reload
      plan_year = employer_profile.plan_years.first

      expect(plan_year.present?).to be_truthy
      expect(plan_year.start_on).to eq default_plan_year_start
    end

    it "should create benefit group with sole source plan offerings" do
      subject.save
      employer_profile = @employer.reload
      plan_year = employer_profile.plan_years.first
      benefit_group = plan_year.benefit_groups.first

      expect(benefit_group.reference_plan).to eq plan
      expect(benefit_group.elected_plan_ids).to eq [plan.id]
      expect(benefit_group.plan_option_kind).to eq 'sole_source'
    end
    
    it "should create composite tiers" do
      subject.save

      employer_profile = @employer.reload
      plan_year = employer_profile.plan_years.first
      benefit_group = plan_year.benefit_groups.first

      composite_tiers = benefit_group.composite_tier_contributions

      employee_tier = composite_tiers.where(composite_rating_tier: "employee_only").first
      expect(employee_tier.offered).to be_truthy
      expect(employee_tier.employer_contribution_percent).to eq record_attrs[:employee_only_rt_contribution].to_f
      expect(employee_tier.final_tier_premium).to eq record_attrs[:employee_only_rt_premium].to_f

      employee_and_spouse_tier = composite_tiers.where(composite_rating_tier: "employee_and_spouse").first
      expect(employee_and_spouse_tier.offered).to be_truthy
      expect(employee_and_spouse_tier.employer_contribution_percent).to eq record_attrs[:employee_and_spouse_rt_contribution].to_f
      expect(employee_and_spouse_tier.final_tier_premium).to eq record_attrs[:employee_and_spouse_rt_premium].to_f

      employee_and_one_or_more_dependents_tier = composite_tiers.where(composite_rating_tier: "employee_and_one_or_more_dependents").first
      expect(employee_and_one_or_more_dependents_tier.offered).to be_falsey
      expect(employee_and_one_or_more_dependents_tier.employer_contribution_percent).to eq record_attrs[:employee_and_one_or_more_dependents_rt_contribution].to_f
      expect(employee_and_one_or_more_dependents_tier.final_tier_premium).to eq record_attrs[:employee_and_one_or_more_dependents_rt_premium].to_f

      family_tier = composite_tiers.where(composite_rating_tier: "family").first
      expect(family_tier.offered).to be_falsey
      expect(family_tier.employer_contribution_percent).to eq record_attrs[:family_rt_contribution].to_f
      expect(family_tier.final_tier_premium).to eq record_attrs[:family_rt_premium].to_f
    end
  end
end
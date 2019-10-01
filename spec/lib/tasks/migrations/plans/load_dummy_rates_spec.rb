require 'spec_helper'

describe "load_dummy_rates" do
  before :all do
    DatabaseCleaner.clean

    glob_pattern = File.join(Rails.root, "db/seedfiles/cca/issuer_profiles_seed.rb")
    load glob_pattern
    load_cca_issuer_profiles_seed

    @start_date = TimeKeeper.date_of_record.all_quarter.min
    @end_date = TimeKeeper.date_of_record.all_quarter.max
    @application_period = Time.utc(@start_date.year, @start_date.month, @start_date.day)..Time.utc(@end_date.year, @end_date.month, @end_date.day)

    issuer_profiles = BenefitSponsors::Organizations::Organization.issuer_profiles.all
    @hp1 = FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[0].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: @application_period))
    @hp2 = FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[1].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: @application_period))
    @hp3 = FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[2].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: Range.new(@application_period.min.months_ago(3), @application_period.max.months_ago(3))))
    @hp4 = FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[3].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: Range.new(@application_period.min.months_ago(3), @application_period.max.months_ago(3))))
    @hp5 = FactoryGirl.create(:benefit_markets_products_product, issuer_profile_id: issuer_profiles[3].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: @application_period))

    Rake.application.rake_require 'tasks/migrations/plans/load_dummy_rates'
    Rake::Task.define_task(:environment)
  end

  context "load_rates" do
    before :each do
      ENV["start_date"] = @end_date.next_month.beginning_of_month.strftime("%Y-%m-%d")
      ENV["action"] = 'load_rates'
    end

    it "should load the dummy data" do
      start_date = @application_period.min.beginning_of_year.to_date
      end_date = @application_period.max.end_of_year.to_date
      pre_table = @hp1.premium_tables.where(:'effective_period.min' => start_date, :'effective_period.max' => end_date).first
      pre_table.update_attributes(effective_period: @application_period)

      @hp1.reload
      expect(@hp1.premium_tables.count).to eq 4
      invoke_dummy_rates_tasks
      @hp1.reload
      expect(@hp1.premium_tables.count).to eq 8
    end

    it "should have premium_tables for dummy" do
      expect(@hp1.premium_tables.where(:"effective_period.min" => @application_period.max.next_month.beginning_of_month).count).to eq 4
    end

    it "should have premium_tuples" do
      dummy1 = @hp1.premium_tables.where(:"effective_period.min" => @application_period.max.next_month.beginning_of_month)
      dummy1_pt = dummy1.first.premium_tuples

      expect(dummy1_pt.present?).to eq true
    end
  end

  context "cleanup_rates" do
    before :each do
      ENV["start_date"] = @end_date.next_month.beginning_of_month.strftime("%Y-%m-%d")
      ENV["action"] = 'cleanup_rates'
    end

    it "should cleanup the dummy data" do
      expect(@hp1.premium_tables.count).to eq 8
      invoke_dummy_rates_tasks
      @hp1.reload
      expect(@hp1.premium_tables.count).to eq 4
    end

    it "should not have premium_tables for dummy" do
      expect(@hp1.premium_tables.where(:"effective_period.min" => @application_period.max.next_month.beginning_of_month).count).to eq 0
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end

def invoke_dummy_rates_tasks
  Rake::Task["dump_dummy:premium_rates"].reenable
  Rake::Task["dump_dummy:premium_rates"].invoke
end

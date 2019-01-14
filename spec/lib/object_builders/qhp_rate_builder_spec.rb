require 'rails_helper'
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_list_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_rate_builder.rb')

describe "QhpRateBuilder", dbclean: :after_each do

  before :each do
    glob_pattern = File.join(Rails.root, "db/seedfiles/cca/issuer_profiles_seed.rb")
    load glob_pattern
    load_cca_issuer_profiles_seed
  end

  let!(:ra1) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: 2018, exchange_provided_code: "R-MA001")}
  let!(:ra2) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: 2018, exchange_provided_code: "R-MA002")}
  let!(:ra3) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: 2018, exchange_provided_code: "R-MA003")}
  let!(:ra4) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: 2018, exchange_provided_code: "R-MA007")}

  let!(:current_time) {Date.new(2018,01,01)}
  let!(:premium_start_date) {current_time.all_quarter.min}
  let!(:premium_end_date) {current_time.all_quarter.max}
  let!(:premium_period) {Time.utc(premium_start_date.year, premium_start_date.month, premium_start_date.day)..Time.utc(premium_end_date.year, premium_end_date.month, premium_end_date.day)}

  let!(:start_date) {current_time.beginning_of_year}
  let!(:end_date) {current_time.end_of_year}
  let!(:application_period) {Time.utc(start_date.year, start_date.month, start_date.day)..Time.utc(end_date.year, end_date.month, end_date.day)}
  let!(:previous_application_period) {Time.utc(start_date.year-1, start_date.month, start_date.day)..Time.utc(end_date.year-1, end_date.month, end_date.day)}

  let!(:issuer_profiles) {BenefitSponsors::Organizations::Organization.issuer_profiles.all}
  let!(:hp1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, application_period: application_period, issuer_profile_id: issuer_profiles[0].issuer_profile.id, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01", premium_tables: build_list(:benefit_markets_products_premium_table, 1, effective_period: premium_period))}
  let!(:hp2) {FactoryBot.create(:benefit_markets_products_health_products_health_product, application_period: previous_application_period, issuer_profile_id: issuer_profiles[0].issuer_profile.id, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01", premium_tables: build_list(:benefit_markets_products_premium_table, 1, effective_period: premium_period))}
  let!(:hp3) {FactoryBot.create(:benefit_markets_products_health_products_health_product, application_period: application_period, issuer_profile_id: issuer_profiles[2].issuer_profile.id, hios_id: "42690MA1234503-01", hios_base_id: "42690MA1234503", csr_variant_id: "01", premium_tables: build_list(:benefit_markets_products_premium_table, 1, effective_period: Range.new(premium_period.min.months_ago(3), premium_period.max.months_ago(3))))}
  let!(:hp4) {FactoryBot.create(:benefit_markets_products_health_products_health_product, application_period: previous_application_period, issuer_profile_id: issuer_profiles[2].issuer_profile.id, hios_id: "42690MA1234503-01", hios_base_id: "42690MA1234503", csr_variant_id: "01", premium_tables: build_list(:benefit_markets_products_premium_table, 1, effective_period: Range.new(premium_period.min.months_ago(3), premium_period.max.months_ago(3))))}

  let!(:plan) {FactoryBot.create(:plan, active_year: 2017)}
  let!(:rating_area) {RatingArea.first || FactoryBot.create(:rating_area)}
  let!(:rates_hash) {{ items: [{
                                      :effective_date => "2017-01-01",
                                      :expiration_date => "2017-12-31",
                                      :plan_id => plan.hios_id,
                                      :age_number => 20,
                                      :primary_enrollee => 256.41,
                                      :rate_area_id => rating_area.rating_area
                                     }]}}

  context "old model" do
    it "should return qhp builder object" do
      rates_runner(rates_hash, 2017)
      plan.reload
      expect(plan.premium_tables.size).to eq 1
      expect(plan.premium_tables.first.age).to eq rates_hash[:items].first[:age_number]
      expect(plan.premium_tables.first.cost).to eq rates_hash[:items].first[:primary_enrollee]
      expect(plan.premium_tables.first.start_on.to_date).to eq rates_hash[:items].first[:effective_date].to_date
      expect(plan.premium_tables.first.end_on.to_date).to eq rates_hash[:items].first[:expiration_date].to_date
    end
  end

  context "new model" do

    before :each do
      rates_runner
      hp1.reload
      hp3.reload
    end

    it "should not load rates for 2017 products hp2 & hp4" do
      expect(hp2.premium_tables.size).to eq 2
      expect(hp4.premium_tables.size).to eq 2
    end

    it "should return 1 tuple with rating area and age from the file" do
      expect(hp1.premium_tables[2].premium_tuples.count).to eq 1
    end

    it "should return 2 tuples with same rating area and different age" do
      expect(hp3.premium_tables[2].premium_tuples.count).to eq 2
    end
  end
end

def rates_runner(rates_hash = nil, set_year = nil)
  @files = Dir.glob(File.join(Rails.root, 'spec/test_data/plan_data/rates/*.xml'))
  year = set_year.nil? ? 2018 : set_year
  action = "new"
  xml = Nokogiri::XML(File.open(@files.first))
  rates = if year < 2018
            Parser::PlanRateGroupParser.parse(xml.root.canonicalize, :single => true)
          else
            Parser::PlanRateGroupListParser.parse(xml.root.canonicalize, :single => true)
          end
  product_rate = QhpRateBuilder.new()
  set_hash = rates_hash.nil? ? rates.to_hash : rates_hash
  product_rate.add(set_hash, action, year)
  product_rate.run
end

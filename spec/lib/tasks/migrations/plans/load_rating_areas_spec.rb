require 'rake'

describe 'load_rate_reference:update_rating_areas' do
  before :all do
    DatabaseCleaner.clean

    Rake.application.rake_require "tasks/migrations/plans/load_rating_areas"
    Rake::Task.define_task(:environment)

    glob_pattern = File.join(Rails.root, "db/seedfiles/cca/locations_seed.rb")
    load glob_pattern
    load_cca_locations_county_zips_seed
  end

  let :run_rake_task do
    Rake::Task["load_rate_reference:update_rating_areas"].reenable
    Rake.application.invoke_task("load_rate_reference:update_rating_areas[#{Rails.root}/spec/test_data/plan_data/rating_areas/2019/SHOP_ZipCode_CY2019_FINAL.xlsx]")
  end

  describe "test rake task" do

    it "should be empty before running rake" do
      expect(RatingArea.all.count).to eq 0
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 0
    end

    it "should be not be empty after running rake" do
      run_rake_task
      expect(RatingArea.all.count).to eq 40
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 7
    end

    context "match attributes for old model" do
      subject { RatingArea.where(zip_code: "01001", county_name: "Hampden", rating_area: "R-MA001").first }
      it { is_expected.to have_attributes(zip_code: subject.zip_code) }
      it { is_expected.to have_attributes(county_name: subject.county_name) }
      it { is_expected.to have_attributes(zip_code_in_multiple_counties: subject.zip_code_in_multiple_counties) }
      it { is_expected.to have_attributes(rating_area: subject.rating_area) }
      it { is_expected.to have_attributes(active_years: subject.active_years) }
    end

    context "match attributes for new model" do
      subject { BenefitMarkets::Locations::RatingArea.where(exchange_provided_code: "R-MA001").first }
      it { is_expected.to have_attributes(exchange_provided_code: subject.exchange_provided_code) }
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end
end

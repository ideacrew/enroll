require 'rake'

describe 'load_rate_reference:update_rating_areas' do
  before :all do
    Rake.application.rake_require "tasks/migrations/load_rate_reference"
    Rake::Task.define_task(:environment)

    files = Dir.glob(File.join(Rails.root, "db/seedfiles/cca/fixtures/locations/county_zips", "**", "*.yaml"))

    files.each do |f_name|
      loaded_class = ::BenefitMarkets::Locations::CountyZip
      yaml_str = File.read(f_name)
      data = YAML.load(yaml_str)
      data.new_record = true
      data.save!
    end
  end

  let :run_rake_task do
    Rake::Task["load_rate_reference:update_rating_areas"].reenable
    Rake.application.invoke_task "load_rate_reference:update_rating_areas"
  end

  describe "test rake task" do

    it "should be empty before running rake" do
      expect(RatingArea.all.count).to eq 0
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 0
    end

    it "should be not be empty after running rake" do
      run_rake_task
      expect(RatingArea.all.count).to eq 698
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 21
    end

    it "should not create multiple records when ran multiple times" do
      run_rake_task
      expect(RatingArea.all.count).to eq 698
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 21
    end

    context "match attributes for old model" do
      subject { RatingArea.first }
      it { is_expected.to have_attributes(zip_code: "01001") }
      it { is_expected.to have_attributes(county_name: "Hampden") }
      it { is_expected.to have_attributes(zip_code_in_multiple_counties: false) }
      it { is_expected.to have_attributes(rating_area: "R-MA001") }
    end

    context "match attributes for new model" do
      subject { BenefitMarkets::Locations::RatingArea.all.first }
      it { is_expected.to have_attributes(exchange_provided_code: "R-MA001") }
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end
end

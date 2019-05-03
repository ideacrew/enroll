require 'rails_helper'

describe "import_counties" do

if Settings.site.key.to_s == "cca" # Countyzip exists only MA
    before :all do
      DatabaseCleaner.clean
      Rake.application.rake_require 'tasks/migrations/plans/import_counties'
      Rake::Task.define_task(:environment)

      file =  File.join(Rails.root, "spec", "test_data/plan_data", "rating_areas","2019/SHOP_ZipCode_CY2019_FINAL.xlsx")
      @files = Dir.glob(file)
      result = Roo::Spreadsheet.open(file)
      sheet_data = result.sheet("Master Zip Code List")
      @raw_info = sheet_data.row(2)
      @last_row = sheet_data.last_row
    end

    context "old model" do

      it "should invoke task" do
        expect(BenefitMarkets::Locations::CountyZip.all.count).to eq 0
        invoke_counties_tasks
      end

      it "should load all county zips from file" do
        expect(BenefitMarkets::Locations::CountyZip.all.count).to eq (2..@last_row).count
      end

      it "should exist in DB as per values from excel" do
        expect(BenefitMarkets::Locations::CountyZip.all.where(county_name: @raw_info[1].squish!,
                                                              zip: @raw_info[0].squish!,
                                                              state: "MA").count).to eq 1
      end
    end

    after :all do
      DatabaseCleaner.clean
    end
  end
end

def invoke_counties_tasks
  Rake::Task["import:county_zips"].invoke(@files.first)
end

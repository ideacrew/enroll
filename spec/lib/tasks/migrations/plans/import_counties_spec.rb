require 'rails_helper'

describe "import_counties" do

  before :all do
    Rake.application.rake_require 'tasks/migrations/plans/import_counties'
    Rake::Task.define_task(:environment)

    file =  File.join(Rails.root, "db", "seedfiles", "plan_xmls","#{Settings.aca.state_abbreviation.downcase}","xls_templates", "SHOP_ZipCode_CY2017_FINAL.xlsx")
    result = Roo::Spreadsheet.open(file)
    sheet_data = result.sheet("Master Zip Code List")
    @raw_info = sheet_data.row(2)
    @last_row = sheet_data.last_row
  end

  context "old model" do

    it "should invoke task" do
      expect(BenefitMarkets::Locations::CountyZip.all.count).to eq 0
      invoke_tasks
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

def invoke_tasks
  Rake::Task["import:county_zips"].invoke
end

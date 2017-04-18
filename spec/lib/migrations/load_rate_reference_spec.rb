require 'rails_helper'
require 'rake'
require 'roo'

RSpec.describe 'Load Rating Regions Task', :type => :task do

  context "rate_reference:update_rating_regions" do
    let(:file_path) { File.join(Rails.root,'lib', 'xls_templates', "SHOP_ZipCode_CY2017_FINAL.xlsx") }
    let(:subject) { Roo::Spreadsheet.open(file_path) }

    before :all do
      Rake.application.rake_require "tasks/migrations/load_rate_reference"
      Rake::Task.define_task(:environment)
    end
    it 'expect not raise errors' do
      expect { invoke_task }.not_to raise_error
    end

    it 'expect to read xlsx file' do
      expect(subject.sheet(0).row(2)).to match_array(["01001", "Hampden", "No", "Rating Area 1"])
      expect(subject.sheet(0).row(3)).to match_array(["01002", "Hampshire", "Yes", "Rating Area 1"])
      expect(subject.sheet(0).row(4)).to match_array(["01002", "Franklin", "Yes", "Rating Area 1"])
      expect(subject.sheet(0).row(699)).to match_array(["02791", "Bristol", "No", "Rating Area 6"])
    end

    it "should have the right data" do
      expect(subject.sheet(0).row(2).first.to_i).to eq RateReference.first.zip_code
      expect(subject.sheet(0).row(2)[1]).to eq RateReference.first.county
      expect(subject.sheet(0).row(2).last).to eq RateReference.first.rating_region
    end

    it "should not have duplicate data" do
      sheet = subject.sheet(0)
      rate_references = RateReference.where(zip_code: sheet.cell(2,1), county: sheet.cell(2,2), multiple_counties: to_boolean(sheet.cell(2,3)),
        rating_region: sheet.cell(2,4))
      expect(rate_references.size).to eq 1
    end

    private

    def invoke_task
      Rake::Task["load_rate_reference:update_rating_regions"].invoke
    end

    def to_boolean(value)
      return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
      return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
    end
  end

end

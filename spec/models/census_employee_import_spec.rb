require 'rails_helper'

RSpec.describe CensusEmployeeImport, :type => :model do

  let(:tempfile) {double("", path:'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx')}
  let(:file) {
    double("", :tempfile=>tempfile)
  }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  context "initialize without employer_role and file" do
    it "throws exception" do
      expect{CensusEmployeeImport.new()}.to raise_error(ArgumentError)
    end
  end

  context "initialize with employer_role and file" do
    it "should not throw an exception" do
      expect{CensusEmployeeImport.new({file:file, employer_profile:employer_profile})}.to_not raise_error
    end
  end
end

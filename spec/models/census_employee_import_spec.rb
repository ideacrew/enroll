require 'rails_helper'

RSpec.describe CensusEmployeeImport, :type => :model do

  let(:tempfile) {double("", path:'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx')}
  let(:file) {
    double("", :tempfile=>tempfile)
  }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:sheet) {
    Roo::Spreadsheet.open(file.tempfile.path).sheet(0)
  }
  let(:subject){
    CensusEmployeeImport.new({file:file, employer_profile:employer_profile})
  }

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

  it "should validate headers" do
    sheet_header_row = sheet.row(1)
    column_header_row = sheet.row(2)
    expect(subject.header_valid?(sheet_header_row) && subject.column_header_valid?(column_header_row)).to be_truthy
  end
end

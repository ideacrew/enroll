require 'rails_helper'

RSpec.describe CensusMember, :type => :model do
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }
  it { should validate_presence_of :dob }

  let(:census_family) { FactoryGirl.build(:employer_census_family) }
  let(:census_employee) { census_family.census_employee }

  it "returns date of births in their respective format" do
    census_employee.save
    expect(census_employee.dob_string).to eq "19801201"
    expect(census_employee.date_of_birth).to eq "12/01/1980"
  end

  it "sets gender" do
    census_employee.gender = "MALE"
    expect(census_employee.gender).to eq "male"
  end

  it "sets date of birth" do
    census_employee.date_of_birth = "12/12/1980"
    expect(census_employee.dob).to eq "12/12/1980".to_date
  end

  context "dob" do
    before(:each) do
      census_employee.date_of_birth = "12/01/1980"
    end

    it "dob_string" do
      expect(census_employee.dob_string).to eq "19801201"
    end

    it "date_of_birth" do
      expect(census_employee.date_of_birth).to eq "12/01/1980"
    end
  end
end

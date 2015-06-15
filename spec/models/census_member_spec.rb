require 'rails_helper'

RSpec.describe CensusMember, :type => :model do
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }
  it { should validate_presence_of :dob }

  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: "1111") }

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

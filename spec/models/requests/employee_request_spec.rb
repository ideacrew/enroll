require 'spec_helper'

describe Requests::EmployeeRequest do
  let(:params) { { } }

  subject { Requests::EmployeeRequest.new(params) }

  describe "with validations" do
    before(:each) { subject.valid? }

    it "should have errors on first_name" do
      expect(subject.errors).to include(:name_first)
    end

    it "should have errors on last_name" do
      expect(subject.errors).to include(:name_last)
    end
  end

  describe "with valid parameters" do
    let(:params) { { 
      :name_first => "A first name",
      :name_last => "A last name",
      :name_middle => "A middle name",
      :ssn => "123456789",
      :dob => "10/3/1950",
      :gender => "female"
    } }


    it "should be valid" do
      expect(subject).to be_valid
    end
  end

end

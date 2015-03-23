require "rails_helper"

describe Forms::ConsumerIdentity do
    it "should have error on dob" do
      subject.valid?
      expect(subject.errors).to include(:date_of_birth)
    end

    it "should have errors on the missing names" do
      subject.valid?
      expect(subject.errors).to include(:last_name)
      expect(subject.errors).to include(:first_name)
    end

    it "should have errors on the ssn" do
      subject.valid?
      expect(subject.errors).to include(:ssn)
    end
end

describe Forms::ConsumerIdentity, "asked to match a census employee" do

  subject { 
    Forms::ConsumerIdentity.new({
      :date_of_birth => "10/12/2012",
      :ssn => "123-45-6789"
    })
  }

  let(:search_params) { {
    :dob => Date.new(2012, 10, 12),
    :ssn => "123456789"
  } }

  let(:census_employee) { double }

  let(:census_employees) { [census_employee] }

  it "should return nothing if that employee does not exist" do
    allow(EmployerCensus::Employee).to receive(:where).and_return([])
    expect(subject.match_census_employee).to be_nil
  end

  it "should return the census employee when one is matched by dob and ssn" do
    allow(EmployerCensus::Employee).to receive(:where).with(search_params).and_return(census_employees)
    expect(subject.match_census_employee).to eq census_employee
  end

end

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

  let(:census_employees) { [double] }

  it "should return nothing if that employee does not exist" do
    allow(EmployerCensus::Employee).to receive(:where).and_return([])
    expect(subject.match_census_employees).to be_empty
  end

  it "should return the census employee when one is matched by dob and ssn" do
    allow(EmployerCensus::Employee).to receive(:where).with(search_params).and_return(census_employees)
    expect(subject.match_census_employees).to eq census_employees
  end

end

describe Forms::ConsumerIdentity, "asked to match a person" do

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

  let(:person) { double }

  let(:people) { [person] }

  it "should return nothing if that person does not exist" do
    allow(Person).to receive(:where).and_return([])
    expect(subject.match_person).to be_nil
  end

  it "should return the person when one is matched by dob and ssn" do
    allow(Person).to receive(:where).with(search_params).and_return(people)
    expect(subject.match_person).to eq person
  end

end

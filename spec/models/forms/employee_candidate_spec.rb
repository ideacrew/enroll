require "rails_helper"

describe Forms::EmployeeCandidate do
    before :each do
      subject.valid?
    end

    it "should have error on dob" do
      expect(subject).to have_errors_on(:date_of_birth)
    end

    it "should have errors on gender" do
      expect(subject).to have_errors_on(:gender)
    end

    it "should have errors on the missing names" do
      expect(subject).to have_errors_on(:last_name)
      expect(subject).to have_errors_on(:first_name)
    end

    it "should have errors on the ssn" do
      expect(subject).to have_errors_on(:ssn)
    end
end

describe Forms::EmployeeCandidate, "asked to match a census employee" do
  let(:fake_org) { instance_double("Organization", :employer_profile => fake_employer) }
  let(:fake_employer) { instance_double("EmployerProfile", :employee_families => [employee_family]) }
  let(:employee_family) { instance_double("EmployerCensus::EmployeeFamily", :census_employee => census_employee, :linked_at => nil) }
  let(:census_employee) { instance_double("EmployerCensus::Employee", :ssn => "123456789", :dob => Date.new(2012,10,12) ) }

  subject {
    Forms::EmployeeCandidate.new({
      :date_of_birth => "10/12/2012",
      :ssn => "123-45-6789"
    })
  }

  let(:search_params) { {
    :dob => Date.new(2012, 10, 12),
    :ssn => "123456789"
  } }

  it "should return nothing if that employee does not exist" do
    allow(Organization).to receive(:where).and_return([])
    expect(subject.match_census_employees).to be_empty
  end

  it "should return the census employee when one is matched by dob and ssn" do
    allow(Organization).to receive(:where).and_return([fake_org])
    expect(subject.match_census_employees).to eq [census_employee]
  end

end

describe Forms::EmployeeCandidate, "asked to match a person" do

  subject {
    Forms::EmployeeCandidate.new({
      :date_of_birth => "10/12/2012",
      :ssn => "123-45-6789",
      :first_name => "yo",
      :last_name => "guy",
      :gender => "m",
      :user_id => 20
    })
  }

  let(:search_params) { {
    :dob => Date.new(2012, 10, 12),
    :ssn => "123456789"
  } }

  let(:user) { nil }
  let(:person) { double(user: user) }

  let(:people) { [person] }

  it "should return nothing if that person does not exist" do
    allow(Person).to receive(:where).and_return([])
    expect(subject.match_person).to be_nil
  end

  context "who does not have a user account associated" do
    it "should return the person when one is matched by dob and ssn" do
      allow(Person).to receive(:where).with(search_params).and_return(people)
      expect(subject.match_person).to eq person
    end
  end

  context "who does have a user acccount associated with current user" do
    let(:user) { double(id: 20) }
    let(:person) { double(user: user) }

    it "should return the person when one is matched by dob and ssn" do
      allow(Person).to receive(:where).with(search_params).and_return(people)
      expect(subject.valid?).to be_truthy
      expect(subject.match_person).to eq person
    end
  end

  context "who does have a user acccount associated" do
    let(:user) { double(id: 12) }
    let(:person) { double(user: user) }

    it "should have an error that the person is associted with another use" do
      allow(Person).to receive(:where).with(search_params).and_return(people)
      subject.valid?
      expect(subject).to have_errors_on(:match)
    end
  end
end

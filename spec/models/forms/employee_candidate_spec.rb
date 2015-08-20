require "rails_helper"

describe Forms::EmployeeCandidate do
  before :each do
    subject.valid?
  end

  it "should have error on dob" do
    expect(subject).to have_errors_on(:dob)
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
  let(:fake_plan_year) { instance_double("PlanYear")}
  let(:census_employee) { instance_double("CensusEmployee", :first_name => "Tom", :last_name => "Baker", :gender => "male", :ssn => "123456789", :dob => Date.new(2012,10,12), :aasm_state => "eligible", :eligible? => true ) }
  let(:fake_employer) { instance_double("EmployerProfile", :census_employees => [census_employee], :plan_years => [fake_plan_year]) }
  let(:fake_org) { instance_double("Organization", :employer_profile => fake_employer) }

  subject {
    Forms::EmployeeCandidate.new({
      :dob => "2012-10-12",
      :ssn => "123-45-6789",
      :first_name => "Tom",
      :last_name => "Baker",
      :gender => "male"
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

  context "and the plan year is not allowing matching" do
    before do
      allow(fake_plan_year).to receive(:is_eligible_to_match_census_employees?).and_return(false)
      allow(Organization).to receive(:where).and_return([fake_org])
    end

    it "should return nothing" do
      expect(subject.match_census_employees).to be_empty
    end

    it "should be valid" do
      expect(subject.valid?).to be_truthy
    end
  end

  context "and the plan year is allowing matching" do
    before do
      allow(CensusEmployee).to receive(:matchable).and_return([census_employee])
    end

    it "should return the census employee when one is matched by dob and ssn" do
      expect(subject.match_census_employees).to eq [census_employee]
    end

    it "should be valid" do
      expect(subject.valid?).to be_truthy
    end
  end
end

describe Forms::EmployeeCandidate, "asked to match a person" do

  subject {
    Forms::EmployeeCandidate.new({
      :dob => "2012-10-12",
      :ssn => "123-45-6789",
      :first_name => "yo",
      :last_name => "guy",
      :gender => "m",
      :user_id => 20
    })
  }

  let(:search_params) { {
    :dob => Date.new(2012, 10, 12),
    :encrypted_ssn => Person.encrypt_ssn("123456789")
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
      expect(subject).to have_errors_on(:base)
    end
  end
end

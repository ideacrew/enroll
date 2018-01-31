require 'rails_helper'

describe Services::EmployeeSignupMatch do
  let(:signup_builder) { instance_double("Factories::MatchedEmployee") }
  let(:form_factory) { class_double("Factories::MatchedEmployee", :new => signup_builder) }
  let(:census_employee_finder) { class_double("EmployerProfile") }
  subject { Services::EmployeeSignupMatch.new(form_factory, census_employee_finder) }

  it "should not match when there is no matching roster entry" do
    consumer_identity = double
    allow(census_employee_finder).to receive(:find_census_employee_by_person).with(consumer_identity).and_return([])
    expect(subject.call(consumer_identity)).to be_nil
  end

  describe "with a matching roster entry" do
    let(:census_employee) { instance_double("CensusEmployee") }
    let(:census_employees) { [census_employee]}
    let(:consumer_identity) { instance_double("Forms::ConsumerIdentity", :match_person => nil) }
    let(:built_form) { double }

    before(:each) do
      allow(census_employee_finder).to receive(:find_census_employee_by_person).with(consumer_identity).and_return(census_employees)
    end

    it "should match that roster entry" do
      allow(signup_builder).to receive(:build).with(consumer_identity, census_employee, nil).and_return(built_form)
      expect(subject.call(consumer_identity)).to eq [census_employee, built_form]
    end

    describe "with a matching person" do
      let(:matched_person) { double }
      let(:consumer_identity) { instance_double("Forms::ConsumerIdentity", :match_person => matched_person) }

      it "should match the person as well" do
        allow(signup_builder).to receive(:build).with(consumer_identity, census_employee, matched_person).and_return(built_form)
        expect(subject.call(consumer_identity)).to eq [census_employee, built_form]
      end
    end
  end
end

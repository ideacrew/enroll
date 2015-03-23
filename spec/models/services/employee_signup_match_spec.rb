require 'rails_helper'

describe Services::EmployeeSignupMatch do
  let(:signup_builder) { instance_double("Factories::EmployeeSignup") }
  let(:form_factory) { class_double("Factories::EmployeeSignup", :new => signup_builder) }
  subject { Services::EmployeeSignupMatch.new(form_factory) }

  it "should not match when there is no matching roster entry" do
    consumer_identity = double
    allow(consumer_identity).to receive(:match_census_employees).and_return([])
    expect(subject.call(consumer_identity)).to be_nil
  end

  describe "with a matching roster entry that is already linked" do
    let(:census_employee) { instance_double("EmployerCensus::Employee", :is_linkable? => false) }
    let(:census_employees) { [census_employee] }
    let(:consumer_identity) { instance_double("Forms::ConsumerIdentity", :match_census_employees => census_employees) }

    it "should not match any roster entries" do
      expect(subject.call(consumer_identity)).to be_nil
    end
  end

  describe "with a matching, unlinked roster entry" do
    let(:census_employee) { instance_double("EmployerCensus::Employee", :is_linkable? => true) }
    let(:census_employees) { [census_employee] }
    let(:consumer_identity) { instance_double("Forms::ConsumerIdentity", :match_census_employees => census_employees, :match_person => nil) }
    let(:built_form) { double }

    it "should match that roster entry" do
      allow(signup_builder).to receive(:build).with(census_employee, nil).and_return(built_form)
      expect(subject.call(consumer_identity)).to eq built_form
    end

    describe "with a matching person" do
      let(:matched_person) { double }
      let(:consumer_identity) { instance_double("Forms::ConsumerIdentity", :match_census_employees => census_employees, :match_person => matched_person) }

      it "should match the person as well" do
        allow(signup_builder).to receive(:build).with(census_employee, matched_person).and_return(built_form)
        expect(subject.call(consumer_identity)).to eq built_form
      end
    end
  end
end

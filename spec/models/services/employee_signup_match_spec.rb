require 'rails_helper'

describe Services::EmployeeSignupMatch do
  let(:consumer_identity) { instance_double("Forms::ConsumerIdentity") }

  it "should not match when there is no matching roster entry" do
    allow(consumer_identity).to receive(:match_census_employee).and_return(nil)
    expect(subject.call(consumer_identity)).to be_nil
  end
end

require "rails_helper"

describe Requests::PersonSignup do
  it "should have error on dob" do
    subject.valid?
    expect(subject.errors).to include(:date_of_birth)
  end
end

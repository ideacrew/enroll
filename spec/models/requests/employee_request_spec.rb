require 'spec_helper'

describe Requests::EmployeeRequest do
  let(:valid_params) { { 
    :name_first => "A first name",
    :name_last => "A last name",
    :ssn => "123456789"
  } }

  subject { Requests::EmployeeRequest.new(valid_params) }

  it "should be valid" do
    expect(subject).to be_valid
  end
end

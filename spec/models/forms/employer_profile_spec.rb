require "rails_helper"

describe Forms::EmployerProfile, "given valid parameters" do
  subject { Forms::EmployerProfile.new }

  before :each do
    subject.valid?
  end

  it "should validate entity_kind" do
    expect(subject).to have_errors_on(:entity_kind)
  end

  it "should validate fein" do
    expect(subject).to have_errors_on(:fein)
  end

  it "should validate dob" do
    expect(subject).to have_errors_on(:dob)
  end

  it "should validate first_name" do
    expect(subject).to have_errors_on(:first_name)
  end

  it "should validate last_name" do
    expect(subject).to have_errors_on(:last_name)
  end

  it "should validate legal_name" do
    expect(subject).to have_errors_on(:legal_name)
  end
end

describe Forms::EmployerProfile, "given more than one office location of the same type" do
  let(:office_location_1) { OfficeLocation.new( :address => Address.new(:kind => "work") ) }
  let(:office_location_2) { OfficeLocation.new( :address => Address.new(:kind => "work") ) }
  subject { Forms::EmployerProfile.new( :office_locations => [office_location_1, office_location_2]) }

  before :each do
    subject.valid?
  end

  it "should be invalid" do
    expect(subject.errors.to_hash[:base]).to include("may not have more than one of the same kind of address")
  end
end

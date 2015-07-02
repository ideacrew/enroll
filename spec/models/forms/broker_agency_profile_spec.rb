require "rails_helper"

describe Forms::BrokerAgencyProfile, "given nothing" do

  subject { Forms::BrokerAgencyProfile.new }

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


describe Forms::BrokerAgencyProfile, ".save" do

  let(:persist_organization) { FactoryGirl.create(:organization, fein: "223230323") }

  let(:attributes) { {
    first_name: 'joe',
    last_name: 'smith',
    dob: "2015-06-01",
    email: 'useraccount@gmail.com',
    npn: "8422323232",
    legal_name: 'useragency',
    fein: "223232323", 
    entity_kind: "c_corporation",
    market_kind: "individual",
    working_hours: "0", 
    accept_new_clients: "0",
    office_locations_attributes: office_locations
    }.merge(other_attributes) }

  let(:other_attributes) { { } }

  let(:office_locations) { { 
    "0" => { 
      address_attributes: address_attributes, 
      phone_attributes: phone_attributes
    }
    }}

  let(:address_attributes) {
    { 
      kind: "primary",
      address_1: "99 N ST", 
      city: "washignton", 
      state: "dc",
      zip: "20006"
    }
  }

  let(:phone_attributes) {
    { 
      kind: "phone main", 
      area_code: "202", 
      number: "324-2232"
    }
  }

  subject {
    Forms::BrokerAgencyProfile.new(attributes)
  }

  context 'when multiple users exists with same personal information' do

    let(:other_attributes) { {
      first_name: "steve",
      last_name: "smith",
      dob: "1974-10-10"
      }}

    before(:each) do 
      2.times { FactoryGirl.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") } 
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base]).to include("too many people match the criteria provided for your identity.  Please contact HBX.")
    end
  end

  context 'when organization already exists with same FEIN' do

    let(:other_attributes) { {
      fein: "223230323"
      }}

    before(:each) do 
      persist_organization # This is to persist organization record in the database
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base]).to include("organization has already been created.")
    end
  end


  context 'when existing user matched with same personal information' do

    let(:other_attributes) { {
      first_name: "joseph",
      last_name: "smith",
      dob: "1974-10-10"
      }}

    before(:each) do 
      FactoryGirl.create(:person, first_name: "joseph", last_name: "smith", dob: "10/10/1974")
      subject.save
    end

    it 'should build broker agency from existing record and set person as primary' do
      person = Person.where(first_name: "joseph", last_name: "smith", dob: "10/10/1974").first
      expect(subject.person).to eq(person)

      organization = Organization.where(fein: subject.fein).first
      expect(organization).to be_truthy
      expect(organization.broker_agency_profile).to be_truthy
      expect(organization.broker_agency_profile.primary_broker_role).to eq(person.broker_role)
      expect(person.broker_role.broker_agency_profile).to eq(organization.broker_agency_profile)
    end
  end

  context 'when person details not matched with existing people' do

    let(:other_attributes) { {
      first_name: 'kevin',
      email: "useraccount2@gmail.com",
      npn: "8022303232",
      fein: "223232300"
      }}

    before(:each) do 
      subject.save
    end

    it 'should build broker agency from new person record and set person as primary' do 
      person = Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob).first
      expect(person).to be_truthy
      expect(person.broker_role).to be_truthy
      expect(person.broker_agency_staff_roles).to be_empty

      organization = Organization.where(fein: subject.fein).first
      expect(organization).to be_truthy
      expect(organization.broker_agency_profile).to be_truthy
      expect(organization.broker_agency_profile.primary_broker_role).to eq(person.broker_role)
      expect(person.broker_role.broker_agency_profile).to eq(organization.broker_agency_profile)
    end
  end
end





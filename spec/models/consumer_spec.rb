require 'rails_helper'

describe Consumer, '.new', type: :model do
  it { should delegate_method(:hbx_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }

  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :gender }
  it { should validate_presence_of :is_incarcerated }
  it { should validate_presence_of :is_applicant }
  it { should validate_presence_of :is_state_resident }
  it { should validate_presence_of :citizen_status }

  it "ssn fails validation with improper value" do
    expect(Consumer.create(ssn: "a7d8d9d").errors[:ssn].any?).to eq true
  end

  it "citizen_status fails validation with an empty or unrecognized value" do
    expect(Consumer.create(citizen_status: "").errors[:citizen_status].any?).to eq true
    expect(Consumer.create(citizen_status: "alaskan").errors[:citizen_status].any?).to eq true
  end

  it "citizen_status succeeds validation with correct value" do
    expect(Consumer.create(citizen_status: "us_citizen").errors[:citizen_status].any?).to eq false
  end

  it 'properly intantiates the class' do
    ssn = "987654321"
    dob = Date.today - 26.years
    gender = "male"

    person = FactoryGirl.build(:person)
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    # Persist Person before building role
    expect(person.save).to eq true

    consumer = person.build_consumer
    consumer.ssn = ssn
    consumer.dob = dob
    consumer.gender = gender
    consumer.is_applicant = true
    consumer.is_incarcerated = false
    consumer.is_state_resident = true
    consumer.citizen_status = 'us_citizen'
    expect(consumer.touch).to eq true

    # Verify delegate local attribute values
    expect(consumer.ssn).to eq ssn
    expect(consumer.dob).to eq dob
    expect(consumer.gender).to eq gender

    # Verify delegated attribute values
    expect(person.ssn).to eq ssn
    expect(person.dob).to eq dob
    expect(person.gender).to eq gender

    expect(consumer.valid?).to eq true
    expect(consumer.errors.messages.size).to eq 0
    expect(consumer.save).to eq true
    expect(consumer.created_at).not_to eq nil
  end

  describe Consumer, '.new', type: :model do
  end


end

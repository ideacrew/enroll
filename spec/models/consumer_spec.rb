require 'rails_helper'

RSpec.describe Consumer, '.new', type: :model do
  it { should delegate_method(:hbx_assigned_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }

  it { should validate_presence_of :person }
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :gender }

  it 'properly intantiates the class using an existing person' do
    ssn = "987654321"
    dob = Date.today - 26.years
    gender = "male"

    person = Person.create(
        first_name: "billy", 
        last_name: "joel",
        addresses: [Address.new(
            kind: "home",
            address_1: "1600 Pennsylvania Ave",
            city: "Washington",
            state: "DC",
            zip: "20001"
          )
        ]
      )

    consumer = person.build_consumer
    consumer.ssn = ssn
    consumer.dob = dob
    consumer.gender = gender
    consumer.is_state_resident = true
    consumer.citizen_status = 'us_citizen'
    # expect(consumer.touch).to eq true

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
    expect(consumer.created_at).to ne nil
  end

  it 'properly intantiates the class using a new person' do
    ssn = "987654321"
    dob = Date.today - 26.years
    gender = "male"

    person = Person.new(
        first_name: "billy", 
        last_name: "joel",
        addresses: [Address.new(
            kind: "home",
            address_1: "1600 Pennsylvania Ave",
            city: "Washington",
            state: "DC",
            zip: "20001"
          )
        ]
      )

    consumer = person.build_consumer
    consumer.ssn = ssn
    consumer.dob = dob
    consumer.gender = gender
    consumer.is_state_resident = true
    consumer.citizen_status = 'us_citizen'

    expect(person.errors.messages.size).to eq 0
    expect(person.save).to eq true

    expect(consumer.touch).to eq true
    expect(consumer.errors.messages.size).to eq 0
    expect(consumer.save).to eq true

    # Verify local attribute values
    expect(consumer.ssn).to eq ssn
    expect(consumer.dob).to eq dob
    expect(consumer.gender).to eq gender

    # Verify delegated attribute values
    expect(person.ssn).to eq ssn
    expect(person.dob).to eq dob
    expect(person.gender).to eq gender
  end
end

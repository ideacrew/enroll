require 'rails_helper'

# Class methods
describe Person, '.new', type: :model do
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }

  # it 'should validate uniqueness of :ssn' do
  #   expect(subject).to validate_uniqueness_of :ssn
  # end

  it 'properly intantiates the class' do
    person = Person.new(
        name_pfx: "mr",
        first_name: "paxton",
        middle_name: "x",
        last_name: "thomas",
        name_sfx: "III"
      )

    expect(person.errors.size).to eq 0
  end
end

describe Person, '.active', type: :model do
  it 'returns only active users' do
    # setup
    active_person = FactoryGirl.build(:person)
    active_person.is_active = true

    non_active_person_1 = FactoryGirl.build(:person)
    non_active_person_1.first_name = "billy"
    non_active_person_1.is_active = false

    non_active_person_2 = FactoryGirl.build(:person)
    non_active_person_2.first_name = "mary"
    non_active_person_2.is_active = false
    ap = active_person.to_a

    expect(ap.size).to eq 1
    expect(ap).to eq [active_person]
  end
end

describe Person, '.addresses', type: :model do
  it 'accepts associated addresses' do
    # setup
    person = FactoryGirl.build(:person)
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    result = person.save

    expect(result).to eq true
    expect(person.addresses.first.kind).to eq "home"
  end
end

# Instance methods
describe Person, '#full_name' do
  it 'returns the concatenated name attributes' do
    p = Person.new(first_name: 'joe', middle_name: 's', last_name: 'cool')

    expect(p.full_name).to eq 'Joe S Cool'
  end
end

describe Person, '#home_phone' do
  it "sets and returns the person's home telephone number" do
    p = Person.new(
        first_name: 'christian',
        last_name: 'bale',
        phones_attributes: [{
          kind: 'home',
          area_code: '202',
          number: '555-1212'
        }]
      )

    expect(p.home_phone.number).to eq '5551212'
  end
end


describe Person, "#subscriber_employee" do
  it "returns employee based on subscriber_type is employee" do
    ssn = "987654321"
    date_of_hire = Date.today - 10.days
    dob = Date.today - 36.years
    gender = "female"

    person = FactoryGirl.build(:person)
    person.subscriber_type = "employee"
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    employee = Employee.new
    employee.ssn = ssn
    employee.dob = dob
    employee.gender = gender
    employee.date_of_hire = date_of_hire
    person.subscriber = employee
    expect(person.subscriber).to eq employee
  end
end


describe Person, "#subscriber_consumer" do
  it "returns employee based on subscriber_type is consumer" do
    ssn = "987654321"
    dob = Date.today - 26.years
    gender = "male"
    person = FactoryGirl.build(:person)
    person.subscriber_type = "broker"
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    consumer = Consumer.new
    consumer.ssn = ssn
    consumer.dob = dob
    consumer.gender = gender
    consumer.is_state_resident = true
    consumer.citizen_status = 'us_citizen'
    person.subscriber = consumer
    expect(person.subscriber).to eq consumer
  end
end

describe Person, "#subscriber_broker" do
  it "returns employee based on subscriber_type is broker" do
   npn_value = "abx123xyz"

    person = FactoryGirl.build(:person)
    person.subscriber_type = "broker"
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    broker = Broker.new(
        npn: npn_value,
        kind: "broker"
    )
    person.subscriber = broker
    expect(person.subscriber).to eq person.broker
  end
end

describe Person, '#families' do
  it 'returns families where the person is present' do
  end
end

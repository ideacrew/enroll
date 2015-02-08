require 'rails_helper'

## Class methods
describe Person, '.new' do
  # it { should validate_presence_of :hbx_assigned_id }
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }

  it "generates hbx_id" do
    expect(Person.create!(first_name: "ginger", last_name: "baker").hbx_id).to eq 10000
  end

  it "ssn invalid with non-numeric value" do
    expect(Person.create(ssn: "a7d8d9d00").errors[:ssn].any?).to eq true
  end

  it "ssn valid with correct numeric-only value" do
    expect(Person.create(ssn: "765890532").errors[:ssn].any?).to eq false
  end

  it "ssn valid with correct value passed in containing dashes" do
    expect(Person.create(ssn: "765-89-0532").errors[:ssn].any?).to eq false
  end

  it "gender invalid with improper value" do
    expect(Person.create(gender: "green").errors[:gender].any?).to eq true
  end

  it "gender valid with correct value" do
    expect(Person.create(gender: "female").errors[:gender].any?).to eq false
  end

  it 'properly intantiates the class' do
    person = Person.new(
        name_pfx: "mr",
        first_name: "paxton",
        middle_name: "x",
        last_name: "thomas",
        name_sfx: "III",
        ssn: "076690012",
        dob: Date.today - 34.years,
        gender: "male",
        updated_by: "rspec"
      )

    expect(person.errors.size).to eq 0
  end
end

describe Person, '.match_by_id_info' do
  let(:p0) { Person.create!(first_name: "jack",   last_name: "bruce",   dob: "1943-05-14", ssn: "517994321") }
  let(:p1) { Person.create!(first_name: "ginger", last_name: "baker",   dob: "1939-08-19", ssn: "888007654") }
  let(:p2) { Person.create!(first_name: "eric",   last_name: "clapton", dob: "1945-03-30", ssn: "666332345") }

  it 'matches by last_name and dob' do
    expect(Person.match_by_id_info(last_name: p0.last_name, dob: p0.dob)).to eq [p0]
  end

  it 'matches by ssn' do
    expect(Person.match_by_id_info(ssn: p1.ssn)).to eq [p1]
  end

  it 'matches by ssn, last_name and dob' do
    expect(Person.match_by_id_info(last_name: p2.last_name, dob: p2.dob, ssn: p2.ssn)).to eq [p2]
  end

  it 'matches multiple records' do
    expect(Person.match_by_id_info(last_name: p2.last_name, dob: p2.dob, ssn: p0.ssn).size).to eq 2
  end

  it 'not match last_name and dob if not on same record' do
    expect(Person.match_by_id_info(last_name: p0.last_name, dob: p1.dob).size).to eq 0
  end

  it 'returns empty array for non-matches' do
    expect(Person.match_by_id_info(ssn: "577600345")).to eq []
  end
end

describe Person, '.active' do
  it 'new person defaults to is_active' do
    expect(Person.create!(first_name: "eric", last_name: "clapton").is_active).to eq true
  end

  it 'returns person records only where is_active == true' do
    p1 = Person.create!(first_name: "jack", last_name: "bruce", is_active: false)
    p2 = Person.create!(first_name: "ginger", last_name: "baker")
    expect(Person.active.size).to eq 1
    expect(Person.active.first).to eq p2
  end
end

## Instance methods
describe Person, '#addresses' do
  it "invalid address bubbles up" do
    person = Person.new
    addresses = person.addresses.build({address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})
    expect(person.valid?).to eq false
    expect(person.errors[:addresses].any?).to eq true
  end

  it 'persists associated address' do
    # setup
    person = FactoryGirl.build(:person)
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    result = person.save

    expect(result).to eq true
    expect(person.addresses.first.kind).to eq "home"
    expect(person.addresses.first.city).to eq "Washington"
  end
end

describe Person, '#person_relationships' do
  it 'accepts associated addresses' do
    # setup
    person = FactoryGirl.build(:person)
    relationship = person.person_relationships.build({kind: "self", relative: person})

    expect(person.save).to eq true
    expect(person.person_relationships.size).to eq 1
    expect(relationship.invert_relationship.kind).to eq "self"
  end
end

describe Person, '#full_name' do
  it 'returns the concatenated name attributes' do
    expect(Person.new(first_name: "ginger", last_name: "baker").full_name).to eq 'Ginger Baker'
  end
end

describe Person, '#phones' do
  it "sets person's home telephone number" do
    person = Person.new
    person.phones.build({kind: 'home', area_code: '202', number: '555-1212'})

    expect(person.phones.first.number).to eq '5551212'
  end
end

describe Person, '#emails' do
  it "sets person's home email" do
    person = Person.new
    person.emails.build({kind: 'home', address: 'sam@example.com'})

    expect(person.emails.first.address).to eq 'sam@example.com'
  end
end

describe Person, '#families' do
  it 'returns families where the person is present' do
  end
end

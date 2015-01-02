require 'rails_helper'

# Class methods
describe Person, '.active' do
  it 'returns only active users' do
    # setup
    active_person = Person.create!(first_name: "joe", last_name: "cool", is_active: true)
    non_active_person = Person.create!(first_name: "mary", last_name: "cool", is_active: false)

    ap = Person.active

    expect(ap.size).to eq 1
    expect(ap).to eq [active_person]
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
          phone_number: '555-1212'
        }]
      )

    expect(p.home_phone.phone_number).to eq '5551212'
  end
end


describe Person, '#families' do
  it 'returns families where the person is present' do
  end
end

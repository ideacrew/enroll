require 'rails_helper'

describe Broker, '.new', :type => :model do
  it 'properly intantiates the class' do

    person = Person.new(
        first_name: "paxton",
        last_name: "thomas",
        addresses: [Address.new(
            kind: "home",
            address_1: "1600 Pennsylvania Ave",
            city: "Washington",
            state: "DC",
            zip: "20001"
          )]
      )

    expect(person.save).to eq true

    npn_value = "xyz123xyz"
    b = person.build_broker(
          npn: npn_value,
          kind: "broker",
          person: person
      )

    expect(b.save).to eq true

    expect(b.id).to eq nil
    qb = Broker.find(person.broker.id)
    expect(qb.npn).to eq npn_value
  end
end



# Class methods

# Instance methods
describe Broker, '.npn', :type => :model do
  it 'returns broker with supplied National Producer Number' do

    npn_value = "abx123xyz"
    broker_one = Broker.create!(
        npn: npn_value,
        kind: "broker",
        person: Person.new(
            first_name: "paxton",
            last_name: "thomas",
            addresses: [Address.new(
                kind: "home",
                address_1: "1600 Pennsylvania Ave",
                city: "Washington",
                state: "DC",
                zip: "20001"
              )]
          )
      )

    expect(broker_one.person.valid?).to eq false

    b = Broker.find_by(npn: npn_value)
    expect(b.inspect).to eq nil
    expect(b.npn).to eq npn_value
  end
end

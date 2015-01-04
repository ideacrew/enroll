require 'rails_helper'

describe Broker, '.new', :type => :model do
  it 'properly intantiates the class' do

    npn_value = "abx123xyz"

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

    person.broker = Broker.new(
        npn: npn_value,
        kind: "broker",
        person: person
      )

    expect(person.save).to eq true

    broker = person.broker

    qb = Broker.find(broker.id)
    expect(qb.npn_value).to eq npn_value
  end
end



# Class methods
describe Broker, '.find_by_npn', :type => :model do
  it 'returns broker with supplied National Producer Number' do

    npn_value = "abx123xyz"
    broker_one = Broker.create(
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

    b = Broker.find_by_npn(npn_value)

    expect(b.npn).to eq npn_value
  end
end

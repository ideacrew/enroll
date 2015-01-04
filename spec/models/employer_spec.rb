require 'rails_helper'

describe Employer, type: :model do
  it { should validate_presence_of :name }
  it { should validate_presence_of :fein }
  it { should validate_presence_of :entity_kind }

  it 'properly intantiates the class' do

    employer = Employer.new(
        name: "ACME Widgets, Inc",
        dba: "Widgetworks",
        fein: "034267123",
        entity_kind: "tax_exempt_organization"
      )

    # Verify attributes
    expect(employer.name).to eq "ACME Widgets, Inc"
    expect(employer.dba).to eq "Widgetworks"
    expect(employer.fein).to eq "034267123"
    expect(employer.entity_kind).to eq "tax_exempt_organization"

    expect(employer.errors.messages.size).to eq 0
    expect(employer.save).to eq true
  end
end

# Class methods
describe Employer, '.find_by_broker_id', :type => :model do
  it 'returns employers represented by the specified broker' do

    id = BSON::ObjectId.from_time(Time.now)
    broker = instance_double("Broker", _id: id)

    employer_one = Employer.new(
        name: "ACME Widgets",
        fein: "034267123",
        entity_kind: "s_corporation",
        broker: broker
      )

    employer_two = Employer.new(
        name: "Megacorp, Inc",
        fein: "427636010",
        entity_kind: "c_corporation",
        broker: broker
      )

    employer_without_broker = Employer.new(
        name: "Tiny Services",
        fein: "576747654",
        entity_kind: "partnership"
      )

    expect(employer_one.broker_id).to eq id

    expect(employer_one.errors.messages.size).to eq 0
    expect(employer_one.save).to eq true
    expect(employer_two.save).to eq true
    expect(employer_without_broker.save).to eq true

    expect(Employer.all.size).to eq 3

    employers_with_broker = Employer.find_by_broker_id(id)
    expect(employers_with_broker.size).to eq 2
  end
end

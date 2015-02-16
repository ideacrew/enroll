require 'rails_helper'

describe Broker do

  let(:person0) {FactoryGirl.create(:person)}
  let(:person1) {FactoryGirl.create(:person)}
  let(:npn0) {"xyz123xyz"}
  let(:npn1) {"123xyz123"}
  let(:provider_kind)  {"assister"}

  # Class methods
  describe Broker, '.new', :type => :model do
    it 'properly intantiates class using build_broker' do
      expect(person0.build_broker(npn: npn0, provider_kind: provider_kind).save).to eq true
    end

    it 'properly intantiates class referencing a parent Person instance' do
      expect(Broker.new(person: person1, npn: npn1, provider_kind: provider_kind).save).to eq true
    end
  end

  describe Broker, '.find', :type => :model do
    it 'returns Broker instance for the specified ID' do
      b0 = Broker.create(person: person0, npn: npn0, provider_kind: provider_kind)

      expect(Broker.find(b0._id)).to be_an_instance_of Broker
      expect(Broker.find(b0._id).npn).to eq b0.npn
    end
  end

  describe Broker, '.all', :type => :model do
    it 'returns all Broker instances' do
      b0 = Broker.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = Broker.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # expect(Broker.all).to be_an_instance_of Mongoid::Criteria
      expect(Broker.all.last).to be_an_instance_of Broker
      expect(Broker.all.size).to eq 2
    end
  end

  describe Broker, '.by_npn', :type => :model do
    it 'returns Broker instance for the specified National Producer Number' do
      b0 = Broker.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = Broker.create(person: person1, npn: npn1, provider_kind: provider_kind)

      expect(Broker.find_by_npn(npn0).npn).to eq b0.npn
    end
  end

  describe Broker, '.all', :type => :model do
    it 'returns all Broker instances' do
      b0 = Broker.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = Broker.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # expect(Broker.all).to be_an_instance_of Mongoid::Criteria
      expect(Broker.all.last).to be_an_instance_of Broker
      expect(Broker.all.size).to eq 2
    end
  end

end


# Instance methods
describe Broker, '.npn', :type => :model do
  # it 'returns broker with supplied National Producer Number' do

  #   ba = FactoryGirl.create(:broker_agency)
  #   npn_value = "abx123xyz"
  #   broker_one = Broker.create!(
  #       broker_agency: ba, 
  #       npn: npn_value,
  #       person: Person.new(
  #           first_name: "paxton",
  #           last_name: "thomas",
  #           addresses: [Address.new(
  #               kind: "home",
  #               address_1: "1600 Pennsylvania Ave",
  #               city: "Washington",
  #               state: "DC",
  #               zip: "20001"
  #             )]
  #         )
  #     )

  #   expect(broker_one.person.valid?).to eq false

  #   b = Broker.find_by(npn: npn_value)
  #   expect(b.inspect).to eq nil
  #   expect(b.npn).to eq npn_value
  # end
end

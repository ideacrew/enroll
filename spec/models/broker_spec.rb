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

  describe Broker, '.find_by_npn', :type => :model do
    it 'returns Broker instance for the specified National Producer Number' do
      b0 = Broker.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = Broker.create(person: person1, npn: npn1, provider_kind: provider_kind)

      expect(Broker.find_by_npn(npn0).npn).to eq b0.npn
    end
  end


  describe Broker, '.find_by_broker_agency', :type => :model do
    let(:ba) {FactoryGirl.create(:broker_agency)}

    it 'returns Broker instance for the specified National Producer Number' do
      b0 = Broker.create(person: person0, npn: npn0, provider_kind: provider_kind, broker_agency: ba)
      b1 = Broker.create(person: person1, npn: npn1, provider_kind: provider_kind, broker_agency: ba)

      expect(Broker.find_by_broker_agency(ba).size).to eq 2
      expect(Broker.find_by_broker_agency(ba).first.broker_agency_id).to eq ba._id
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

# Instance methods

end

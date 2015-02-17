require 'rails_helper'

describe Broker, type: :model do

  let(:person0) {FactoryGirl.create(:person)}
  let(:person1) {FactoryGirl.create(:person)}
  let(:broker_agency) {FactoryGirl.create(:broker_agency)}
  let(:npn0) {"xyz123xyz"}
  let(:npn1) {"123xyz123"}
  let(:provider_kind)  {"assister"}


  describe ".new" do
    let(:valid_params) do
      { person: person0,
        npn: npn0,
        provider_kind: provider_kind
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(Broker.new(**params).save).to be_false
      end
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}

      it "should raise" do
        expect{Broker.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:npn)}

      it "should fail validation" do
        expect(Broker.create(**params).errors[:npn].any?).to be_true
      end
    end

    context "with no provider_kind" do
      let(:params) {valid_params.except(:provider_kind)}

      it "should fail validation" do
        expect(Broker.create(**params).errors[:provider_kind].any?).to be_true
      end
    end

    context "with all required data" do
      let(:params) {valid_params}

      it "should successfully save" do
        expect(Broker.new(**params).save).to be_true
      end

      it 'successfully save using build_broker' do
        expect(person0.build_broker(**params.except(:person)).save).to eq true
      end

    end

    context "with duplicate npn number" do
      let(:params) {valid_params}

      it "should raise" do
        expect(Broker.with(safe: true).create(**params)).to be_true

        ## TODO: Change this to proper Error when Mongoid is coerced into raising it
        # expect{Broker.with(safe: true).create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end
  end


  # Class methods
  describe Broker, '.new', :type => :model do

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
  describe Broker, :type => :model do
    let(:ba) {FactoryGirl.create(:broker_agency)}

    it '#broker_agency sets agency' do
      expect(Broker.new(broker_agency: ba).broker_agency.id).to eq ba._id
    end

    it '#has_broker_agency? is true when agency is assigned' do
      expect(Broker.new(broker_agency: nil).has_broker_agency?).to be_false
      expect(Broker.new(broker_agency: ba).has_broker_agency?).to be_true
    end

    # TODO
    it '#address= and #address sets & gets work address on parent person instance' do
      # address = FactoryGirl.build(:address)
      # address.kind = "work"
      
      # expect(person0.build_broker(address: address).address._id).to eq address._id
      # expect(person0.build_broker(npn: npn0, provider_kind: provider_kind, address: address).save).to eq true
    end



  end


end

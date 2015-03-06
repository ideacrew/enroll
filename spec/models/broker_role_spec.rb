require 'rails_helper'

describe BrokerRole, type: :model do

  let(:address) {FactoryGirl.build(:address)}
  let(:saved_person) {FactoryGirl.create(:person, addresses: [address])}

  let(:person0) {FactoryGirl.create(:person)}
  let(:person1) {FactoryGirl.create(:person)}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile)}
  let(:npn0) {"xyz123xyz"}
  let(:npn1) {"123xyz123"}
  let(:provider_kind)  {"assister"}


  describe ".new" do
    let(:valid_params) do
      { 
        person: saved_person,
        npn: npn0,
        provider_kind: provider_kind
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(BrokerRole.new(**params).save).to be_false
      end
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}

      it "should raise" do
        expect{BrokerRole.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:npn)}

      it "should fail validation" do
        expect(BrokerRole.create(**params).errors[:npn].any?).to be_true
      end
    end

    context "with no provider_kind" do
      let(:params) {valid_params.except(:provider_kind)}

      it "should fail validation" do
        expect(BrokerRole.create(**params).errors[:provider_kind].any?).to be_true
      end
    end

    context "with all required data" do
      let(:broker_role) {saved_person.build_broker_role(valid_params)}

      it "should save" do
        expect(broker_role.save).to be_true
      end

      context "and it is saved" do
        before do
          broker_role.save
        end

        it "should be findable" do
          expect(BrokerRole.find(broker_role.id).id.to_s).to eq broker_role.id.to_s
        end
      end
    end

    context "with duplicate npn number" do
      let(:params) {valid_params}

      it "should raise" do
        expect(BrokerRole.with(safe: true).create(**params)).to be_true

        ## TODO: Change this to proper Error when Mongoid is coerced into raising it
        # expect{BrokerRole.with(safe: true).create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end
  end


  # Class methods
  describe BrokerRole, '.new', :type => :model do

  end

  describe BrokerRole, '.find', :type => :model do
    it 'returns Broker instance for the specified ID' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)

      expect(BrokerRole.find(b0._id)).to be_an_instance_of BrokerRole
      expect(BrokerRole.find(b0._id).npn).to eq b0.npn
    end
  end

  describe BrokerRole, '.all', :type => :model do
    it 'returns all Broker instances' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # expect(BrokerRole.all).to be_an_instance_of Mongoid::Criteria
      expect(BrokerRole.all.last).to be_an_instance_of BrokerRole
      expect(BrokerRole.all.size).to eq 2
    end
  end

  describe BrokerRole, '.find_by_npn', :type => :model do
    it 'returns Broker instance for the specified National Producer Number' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      expect(BrokerRole.find_by_npn(npn0).npn).to eq b0.npn
    end
  end


  describe BrokerRole, '.find_by_broker_agency_profile', :type => :model do
    let(:ba) {FactoryGirl.create(:broker_agency_profile)}

    it 'returns Broker instance for the specified National Producer Number' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind, broker_agency_profile: ba)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind, broker_agency_profile: ba)

      expect(BrokerRole.find_by_broker_agency_profile(ba).size).to eq 2
      expect(BrokerRole.find_by_broker_agency_profile(ba).first.broker_agency_profile_id).to eq ba._id
    end
  end


  describe BrokerRole, '.all', :type => :model do
    it 'returns all Broker instances' do
      b0 = BrokerRole.create(person: person0, npn: npn0, provider_kind: provider_kind)
      b1 = BrokerRole.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # expect(BrokerRole.all).to be_an_instance_of Mongoid::Criteria
      expect(BrokerRole.all.last).to be_an_instance_of BrokerRole
      expect(BrokerRole.all.size).to eq 2
    end
  end

  # Instance methods
  describe BrokerRole, :type => :model do
    let(:ba) {FactoryGirl.create(:broker_agency_profile)}

    it '#broker_agency_profile sets agency' do
      expect(BrokerRole.new(broker_agency_profile: ba).broker_agency_profile.id).to eq ba._id
    end

    it '#has_broker_agency_profile? is true when agency is assigned' do
      expect(BrokerRole.new(broker_agency_profile: nil).has_broker_agency_profile?).to be_false
      expect(BrokerRole.new(broker_agency_profile: ba).has_broker_agency_profile?).to be_true
    end

    # TODO
    it '#address= and #address sets & gets work address on parent person instance' do
      # address = FactoryGirl.build(:address)
      # address.kind = "work"

      # expect(person0.build_broker_role(address: address).address._id).to eq address._id
      # expect(person0.build_broker_role(npn: npn0, provider_kind: provider_kind, address: address).save).to eq true
    end
  end

end

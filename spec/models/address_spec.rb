require 'rails_helper'

describe Address, type: :model do
  it { should validate_presence_of :address_1 }
  it { should validate_presence_of :city }
  it { should validate_presence_of :state }
  it { should validate_presence_of :zip }

  describe 'kind' do
    it "invalid with blank value" do
      expect(Address.create(kind: "").errors[:kind].any?).to eq true
    end

    it "invalid with unrecognized value" do
      expect(Address.create(kind: "fake").errors[:kind].any?).to eq true
    end

    it 'accepts all valid values' do
      ['home', 'work', 'mailing'].each do |type|
        expect(Address.create(kind: type).errors[:kind].any?).to eq false
      end
    end
  end


  it "zipcode is invalid with empty or unrecognized value" do
    expect(Address.create(zip: "").errors[:zip].any?).to eq true
    expect(Address.create(zip: "324-67").errors[:zip].any?).to eq true
  end

  describe "with a zipcode of 99389" do
    it "should have a valid zipcode" do
      expect(Address.create(zip: "99389").errors[:zip].any?).to eq false
      expect(Address.create(zip: "99389-3425").errors[:zip].any?).to eq false
    end
  end

  describe 'view helpers/presenters' do
    let(:address) { FactoryGirl.build :address }
    describe '#formatted_address' do
      it 'returns a string with a formated address' do
        line_one = address.address_1
        line_two = address.address_2
        line_three = "#{address.city}, #{address.state} #{address.zip}"

        expect(address.formatted_address).to eq "#{line_one}<br/>#{line_two}<br/>#{line_three}"
      end
    end

    describe '#full_address' do
      it 'returns the full address in a single line' do
        expected_result = "#{address.address_1} #{address.address_2} #{address.city}, #{address.state} #{address.zip}"
        expect(address.full_address).to eq expected_result
      end
    end
  end

  describe '#home?' do
    context 'when not a home address' do
      it 'returns false' do
        address = Address.new(kind: 'work')
        expect(address.home?).to be false
      end
    end

    context 'when a home address' do
      it 'returns true' do
        address = Address.new(kind: 'home')
        expect(address.home?).to be true
      end
    end
  end

  describe '#clean_fields' do
    it 'removes trailing and leading whitespace from fields' do
      address = Address.new
      address.address_1 = '   4321 Awesome Drive   '
      address.address_2 = '   #321   '
      address.city = '   Washington    '
      address.state = '    DC     '
      address.zip = '   20002    '

      address.clean_fields

      expect(address.address_1).to eq '4321 Awesome Drive'
      expect(address.address_2).to eq '#321'
      expect(address.city).to eq 'Washington'
      expect(address.state).to eq 'DC'
      expect(address.zip).to eq '20002'
    end
  end

  describe '#match' do
    let(:address) { FactoryGirl.build :address }

    context 'addresses are the same' do
      let(:second_address) { address.clone }
      it 'returns true' do
        expect(address.match(second_address)).to be true
      end

      context 'mismatched case' do
        before { second_address.address_1.upcase! }
        it 'returns true' do
          expect(address.match(second_address)).to be true
        end
      end
    end

    context 'addresses differ' do
      let(:second_address) do
        a = address.clone
        a.state = 'AL'
        a
      end
      it 'returns false' do
        expect(address.match(second_address)).to be false
      end
    end
  end
end

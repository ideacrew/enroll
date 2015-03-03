require 'rails_helper'

RSpec.describe Address, type: :model do
  it { should validate_presence_of :address_1 }
  it { should validate_presence_of :city }
  it { should validate_presence_of :state }
  it { should validate_presence_of :zip }

  let(:person) {Person.new(first_name: "John", last_name: "Doe", gender: "male", dob: "10/10/1974", ssn: "123456789" )}
  let(:address) {FactoryGirl.create(:address)}
  let(:employer){FactoryGirl.create(:employer_profile)}

  describe "add address" do
    let(:valid_params) do
      {
        kind: "home",
        address_1: "1 Clear Crk",
        city: "Irvine",
        state: "CA",
        zip: "20171"
      }
    end

    context "with no arguments" do
      let(:params){{}}
      it "should not save" do
        expect(Address.create(**params).valid?).to be_false
      end
    end

    context "with empty address kind" do
      let(:params) {valid_params.except(:kind)}
      it "is not a valid address kind" do
        expect(Address.create(**params).errors[:kind].any?).to be_true
      end
    end

    context "with no address_1" do
      let(:params) {valid_params.except(:address_1)}
      it "is not a valid address kind" do
        expect(Address.create(**params).errors[:address_1].any?).to be_true
      end
    end

    context "with no city" do
      let(:params) {valid_params.except(:city)}
      it "is not a valid address" do
        expect(Address.create(**params).errors[:city].any?).to be_true
      end
    end

    context "with no state" do
      let(:params) {valid_params.except(:state)}
      it "is not valid address" do
        expect(Address.create(**params).errors[:state].any?).to be_true
      end
    end

    context "zip" do
      let(:params) {valid_params.except(:zip)}

      it "is empty" do
        expect(Address.create(**params).errors[:zip].any?).to be_true
      end

      it "is not valid with invalid code" do
        params.deep_merge!({zip: "123-24"})
        expect(Address.create(**params).errors[:zip].any?).to be_true
      end

    end

    context "with invalid address kind" do
      let(:params) {valid_params.deep_merge!({kind: "fake"})}
      it "is with unrecognized value" do
        expect(Address.create(**params).errors[:kind].any?).to be_true
      end
    end

    context "accepts all valid values" do
      let(:params) {valid_params.except(:kind)}
      it "should save the address" do
        ['home', 'work', 'mailing'].each do |type|
          params.deep_merge!({kind: type})
          address = Address.new(**params)
          person.addresses << address
          expect(address.errors[:kind].any?).to be_false
          expect(address.valid?).to be_true
        end
      end
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

      expect(Address.new(address_1: '   4321 Awesome Drive   ').address_1).to eq '4321 Awesome Drive'
      expect(Address.new(address_2: '   NW   ').address_2).to eq 'NW'
      expect(Address.new(address_3: '   Apt 6   ').address_3).to eq 'Apt 6'
      expect(Address.new(city: '   Washington   ').city).to eq 'Washington'
      expect(Address.new(state: '   DC   ').state).to eq 'DC'
      expect(Address.new(zip: '   20002   ').zip).to eq '20002'
    end
  end

  describe '#matches?' do
    let(:address) { FactoryGirl.build :address }

    context 'addresses are the same' do
      let(:second_address) { address.clone }
      it 'returns true' do
        expect(address.matches?(second_address)).to be_true
      end

      context 'mismatched case' do
        before { second_address.address_1.upcase! }
        it 'returns true' do
          expect(address.matches?(second_address)).to be_true
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
        expect(address.matches?(second_address)).to be_false
      end
    end
  end
end

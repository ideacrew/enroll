require 'rails_helper'

describe Address do
  it "should have an invalid zipcode" do
    subject.valid?
    expect(subject).to have_at_least(1).errors_on(:zip)
  end

  describe "with a zipcode of 99389" do
    it "should have a valid zipcode" do
      subject.zip = "99389"
      subject.valid?
      expect(subject).not_to have_at_least(1).errors_on(:zip)
    end
  end

  describe 'validations' do
    describe 'presence' do
      [:address_1, :city, :state, :zip].each do |missing|
        it ('is invalid without ' + missing.to_s) do
          trait = 'without_' + missing.to_s
          address = build(:address, trait.to_sym)
          expect(address).to be_invalid
        end
      end
    end

    describe 'address type' do
      let(:address) { build(:address, :with_invalid_address_type) }
      context 'when invalid' do
        it 'is invalid' do
          expect(address).to be_invalid
        end
      end

      ['home', 'work', 'mailing'].each do |type|
        context('when ' + type) do
          before { address.address_type = type}
          it 'is valid' do
            expect(address).to be_valid
          end
        end
      end
    end
  end

  describe 'view helpers/presenters' do
    let(:address) { build :address }
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
        address = Address.new(address_type: 'work')
        expect(address.home?).to be_false
      end
    end

    context 'when a home address' do
      it 'returns true' do
        address = Address.new(address_type: 'home')
        expect(address.home?).to be_true
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
    let(:address) { build :address }

    context 'addresses are the same' do
      let(:second_address) { address.clone }
      it 'returns true' do
        expect(address.match(second_address)).to be_true
      end

      context 'mismatched case' do
        before { second_address.address_1.upcase! }
        it 'returns true' do
          expect(address.match(second_address)).to be_true
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
        expect(address.match(second_address)).to be_false
      end
    end
  end
end

require 'spec_helper'

describe Phone do

  describe 'validations' do
    describe 'phone type' do
      let(:phone) { Phone.new(kind: 'invalid', number: "12345") }
      context 'when invalid' do
        it 'is invalid' do
          expect(phone).to be_invalid
        end
      end
      valid_types = ['home', 'work', 'mobile']
      valid_types.each do |type|
        context('when ' + type) do
          before {
            phone.number = "12345"
            phone.kind = type
          }
          it 'is valid' do
            expect(phone).to be_valid
          end
        end
      end
    end
  end

  describe '#match' do
    let(:phone) do
      p = Phone.new
      p.kind = 'home'
      p.number = '222-222-2222'
      p.extension = '12'
      p
    end

    context 'phones are the same' do
      let(:other_phone) { phone.clone }
      it 'returns true' do
        expect(phone.match(other_phone)).to be true
      end
    end

    context 'phones differ' do
      context 'by type' do
        let(:other_phone) do
          p = phone.clone
          p.kind = 'work'
          p
        end
        it 'returns false' do
          expect(phone.match(other_phone)).to be false
        end
      end
      context 'by number' do
        let(:other_phone) do
          p = phone.clone
          p.number = '666-666-6666'
          p
        end
        it 'returns false' do
          expect(phone.match(other_phone)).to be false
        end
      end
    end
  end

  describe 'changing phone number' do
    let(:phone) { Phone.new }
    it 'removes non-numerals' do
      phone.number = 'a1b2c3d4'
      expect(phone.number).to eq '1234'
    end
  end

  describe 'changing phone extension' do
    let(:phone) { Phone.new }
    it 'removes non-numerals' do
      phone.extension = 'a1b2c3d4'
      expect(phone.extension).to eq '1234'
    end
  end
end

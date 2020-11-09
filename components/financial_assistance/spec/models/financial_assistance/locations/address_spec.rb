# frozen_string_literal: true

require 'rails_helper'

module FinancialAssistance
  RSpec.describe Locations::Address, 'address validations' do
    describe 'with proper validations' do
      let(:address_kind) {'home'}
      let(:address_1) {'1 Clear Crk'}
      let(:city) {'Irvine'}
      let(:state) {'CA'}
      let(:zip) {'20171'}

      let(:address_params) do
        {
          kind: address_kind,
          address_1: address_1,
          city: city,
          state: state,
          zip: zip
        }
      end

      subject {FinancialAssistance::Locations::Address.new(address_params)}

      before :each do
        subject.valid?
      end

      context 'with no arguments' do
        let(:address_params) {{}}
        it 'should not be valid' do
          expect(subject.valid?).to be_falsey
        end
      end

      context 'with empty address kind' do
        let(:address_kind) {nil}
        it 'is not a valid address kind' do
          expect(subject.errors[:kind].any?).to be_truthy
        end
      end

      context 'with no address_1' do
        let(:address_1) {nil}
        it 'is not a valid address kind' do
          expect(subject.errors[:address_1].any?).to be_truthy
        end
      end

      context 'with no city' do
        let(:city) {nil}
        it 'is not a valid address' do
          expect(subject.errors[:city].any?).to be_truthy
        end
      end

      context 'with no state' do
        let(:state) {nil}
        it 'is not valid address' do
          expect(subject.errors[:state].any?).to be_truthy
        end
      end

      context 'with no zip' do
        let(:zip) {nil}

        it 'is empty' do
          expect(subject.errors[:zip].any?).to be_truthy
        end
      end

      context 'with an invalid zip' do
        let(:zip) {'123-24'}
        it 'is not valid with invalid code' do
          expect(subject.errors[:zip].any?).to be_truthy
        end
      end


      context 'with invalid address kind' do
        let(:address_kind) {'fake'}

        it 'is with unrecognized value' do
          expect(subject.errors[:kind].any?).to be_truthy
        end
      end

      context 'embedded in another object', type: :model do
        it {should validate_presence_of :address_1}
        it {should validate_presence_of :city}
        it {should validate_presence_of :state}
        it {should validate_presence_of :zip}

        let(:person) {Person.new(first_name: 'John', last_name: 'Doe', gender: 'male', dob: '10/10/1974', ssn: '123456789')}
        let(:address) {FactoryBot.create(:address)}
        let(:employer) {FactoryBot.create(:employer_profile)}


        context 'accepts all valid values' do
          let(:params) {address_params.except(:kind)}
          it 'should save the address' do
            ['home', 'work', 'mailing'].each do |type|
              params.deep_merge!({kind: type})
              address = FinancialAssistance::Locations::Address.new(**params)
              person.addresses << address
              expect(address.errors[:kind].any?).to be_falsey
              expect(address.valid?).to be_truthy
            end
          end
        end
      end

    end

    describe 'view helpers/presenters' do
      let(:address) do
        FinancialAssistance::Locations::Address.new(
          address_1: "An address line 1",
          address_2: "An address line 2",
          city: "A City",
          state: "CA",
          zip: "21222"
        )
      end

      describe '#to_s' do
        it 'returns a string with a formated address' do
          line_one = address.address_1
          line_two = address.address_2
          line_three = "#{address.city}, #{address.state} #{address.zip}"

          expect(address.to_s).to eq "#{line_one}<br/>#{line_two}<br/>#{line_three}"
        end
      end

      describe '#full_address' do
        it 'returns the full address in a single line' do
          expected_result = "#{address.address_1} #{address.address_2} #{address.city}, #{address.state} #{address.zip}"
          expect(address.full_address).to eq expected_result
        end
      end

      describe '#to_html' do
        it 'returns the address with html tags' do
          expect(address.to_html).to eq "<div>An address line 1</div><div>An address line 2</div><div>A City, CA 21222</div>"
        end

        it 'retuns address with html tags if no address_2 field is present' do
          address.address_2 = ''
          expect(address.to_html).to eq "<div>An address line 1</div><div>A City, CA 21222</div>"
        end
      end
    end

    describe '#work?' do
      context 'when not a work address' do
        it 'returns false' do
          address = FinancialAssistance::Locations::Address.new(kind: 'home')
          expect(address.work?).to be false
        end
      end

      context 'when a work address' do
        it 'returns true' do
          address = FinancialAssistance::Locations::Address.new(kind: 'work')
          expect(address.work?).to be true
        end
      end
    end

    describe '#clean_fields' do
      it 'removes trailing and leading whitespace from fields' do

        expect(FinancialAssistance::Locations::Address.new(address_1: '   4321 Awesome Drive   ').address_1).to eq '4321 Awesome Drive'
        expect(FinancialAssistance::Locations::Address.new(address_2: '   NW   ').address_2).to eq 'NW'
        expect(FinancialAssistance::Locations::Address.new(address_3: '   Apt 6   ').address_3).to eq 'Apt 6'
        expect(FinancialAssistance::Locations::Address.new(city: '   Washington   ').city).to eq 'Washington'
        expect(FinancialAssistance::Locations::Address.new(state: '   DC   ').state).to eq 'DC'
        expect(FinancialAssistance::Locations::Address.new(zip: '   20002   ').zip).to eq '20002'
      end
    end

    describe '#matches_addresses?' do
      let(:address) do
        FinancialAssistance::Locations::Address.new(
          address_1: 'An address line 1',
          address_2: 'An address line 2',
          city: 'A City',
          state: 'CA',
          zip: '21222'
        )
      end

      context 'addresses are the same' do
        let(:second_address) {address.clone}
        it 'returns true' do
          expect(address.same_address?(second_address)).to be_truthy
        end

        context 'mismatched case' do
          before {second_address.address_1.upcase!}
          it 'returns true' do
            expect(address.same_address?(second_address)).to be_truthy
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
          expect(address.same_address?(second_address)).to be_falsey
        end
      end
    end

    describe '#kind' do
      it 'should write and return work' do
        subject.write_attribute(:kind, 'work')
        expect(subject.kind).to eq 'work'
      end
    end
  end
end

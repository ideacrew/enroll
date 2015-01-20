require 'spec_helper'

describe Email do

  describe 'validations' do
    describe 'email type' do
      let(:email) { Email.new(kind: 'invalid', address: 'example@example.com') }
      context 'when invalid' do
        it 'is invalid' do
          expect(email).to be_invalid
        end
      end
      valid_types = ['home', 'work']
      valid_types.each do |type|
        context('when ' + type) do
          before { email.kind = type}
          it 'is valid' do
            expect(email).to be_valid
          end
        end
      end
    end

    describe 'presence' do
      [:address].each do |missing|
        it('is invalid without ' + missing.to_s) do
          trait = 'without_email_' + missing.to_s
          email = FactoryGirl.build(:email, trait.to_sym)
          expect(email).to be_invalid
        end
      end
    end
  end

  describe '#match' do
    let(:email) { Email.new(kind: 'home', address: 'example@example.com') }
    context 'emails are the same' do
      let(:other_email) { email.clone }
      it 'returns true' do
        email.errors[:kind] == ["invalid is not a valid email type"]
      end
    end

    context 'emails differ' do
      context 'by type' do
        let(:other_email) do
          e = email.clone
          e.kind = 'work'
          e
        end
        it 'returns false' do
          expect(email.match(other_email)).to be false
        end
      end

      context 'by address' do
        let(:other_email) do
          e = email.clone
          e.address = 'something@different.com'
          e
        end
        it 'returns false' do
          expect(email.match(other_email)).to be false
        end
      end
    end
  end
end

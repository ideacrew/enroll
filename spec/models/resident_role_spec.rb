require 'rails_helper'
require 'aasm/rspec'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe ResidentRole, :type => :model do
    it { should delegate_method(:hbx_id).to :person }
    it { should delegate_method(:ssn).to :person }
    it { should delegate_method(:dob).to :person }
    it { should delegate_method(:gender).to :person }
    it { should delegate_method(:is_incarcerated).to :person }
    it { should validate_presence_of :gender }
    it { should validate_presence_of :dob }

    describe 'rating_address' do
      subject { person.resident_role.rating_address }

      let(:person) { create(:person, :with_resident_role, addresses: addresses) }
      let(:mailing_address) { build(:address, kind: :mailing) }
      let(:home_address) { build(:address, kind: :home) }

      context 'when resident has both mailing and home address' do
        let(:addresses) { [mailing_address, home_address] }

        it 'should return home address' do
          expect(subject).to eq home_address
        end
      end

      context 'when resident has mailing address only' do
        before do
          person.addresses = addresses
          person.save!
        end

        let(:addresses) { [mailing_address] }

        it 'should return mailing address' do
          expect(subject).to eq mailing_address
        end
      end

      context 'when resident has home address only' do
        let(:addresses) { [home_address] }

        it 'should return home address' do
          expect(subject).to eq home_address
        end
      end
    end
  end
end

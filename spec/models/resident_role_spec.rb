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

    describe 'create default osse eligibility on create' do
      let(:consumer_role) { FactoryBot.build(:consumer_role) }
      let(:current_year) { TimeKeeper.date_of_record.year }

      context 'when osse feature for the given year is disabled' do
        before do
          EnrollRegistry["aca_ivl_osse_eligibility_#{current_year}"].feature.stub(:is_enabled).and_return(false)
        end

        it 'should create osse eligibility in initial state' do
          expect(consumer_role.eligibilities.count).to eq 0
          consumer_role.save
          expect(consumer_role.reload.eligibilities.count).to eq 0
        end
      end

      context 'when osse feature for the given year is enabled' do
        before do
          EnrollRegistry["aca_ivl_osse_eligibility_#{current_year}"].feature.stub(:is_enabled).and_return(true)
        end

        it 'should create osse eligibility in initial state' do
          expect(consumer_role.eligibilities.count).to eq 0
          consumer_role.save!
          expect(consumer_role.reload.eligibilities.count).to eq 1
          eligibility = consumer_role.eligibilities.first
          expect(eligibility.key).to eq :ivl_osse_eligibility
          expect(eligibility.current_state).to eq :initial
          expect(eligibility.state_histories.count).to eq 1
          expect(eligibility.evidences.count).to eq 1
          evidence = eligibility.evidences.first
          expect(evidence.key).to eq :ivl_osse_evidence
          expect(evidence.current_state).to eq :initial
          expect(evidence.state_histories.count).to eq 1
        end
      end
    end
  end
end

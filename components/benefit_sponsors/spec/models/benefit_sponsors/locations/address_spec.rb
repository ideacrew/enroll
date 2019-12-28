require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Locations::Address, type: :model, :dbclean => :after_each do

    let(:subject) { BenefitSponsors::Locations::Address.new(zip: '10010', kind: 'primary', address_1: 'xyz', city: 'test', state: 'MA') }
    let(:office_location) {}
    describe "MA" do
      context "valid address" do
        before :each do
          allow(subject).to receive(:office_location).and_return double(profile: double(_type: "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile"))
          subject.county = "Hampden"
        end

        it 'should return true for MA' do
          expect(subject.valid?).to eq true
        end
      end

      context "invalid address" do
        before :each do
          allow(subject).to receive(:office_location).and_return double(profile: double(_type: "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile"))
        end

        it 'should return false for MA' do
          expect(subject.valid?).to eq false
        end

        it 'should return true for non primary in MA' do
          subject.kind = "mailing"
          expect(subject.valid?).to eq true
        end
      end
    end

    describe "DC" do
      context "valid address" do
        before :each do
          allow(subject).to receive(:office_location).and_return double(profile: double(_type: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile"))
          subject.county = nil
        end

        it 'should return true for DC' do
          expect(subject.valid?).to eq true
        end
      end

      context "invalid address" do
        before :each do
          allow(subject).to receive(:office_location).and_return double(profile: double(_type: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile"))
          subject.zip = nil
        end

        it 'should return true for DC' do
          expect(subject.valid?).to eq false
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Accounts::GeneralAgencyAccount, type: :model, dbclean: :after_each do

    let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site, legal_name: 'General Agency Profile') }
    let(:general_agency_profile) { general_agency.profiles.first }
    let(:general_agency_account) { FactoryBot.build(:sponsored_benefits_accounts_general_agency_account, general_agency_profile: general_agency_profile, general_agency_profile_id: 'old_profile_id')}

    after :all do
      Rails.cache.clear
      DatabaseCleaner.clean
    end

    context "#ga_name" do
      context 'with general-agency-name cached' do
        before :each do
          Rails.cache.write("general-agency-name-#{general_agency_profile.id}", 'NEW AGENCY PROFILE')
          Rails.cache.write('general-agency-name-old_profile_id', 'OLD AGENCY PROFILE')
        end

        it 'should get the cached name for benefit sponsor general agency profile' do
          expect(general_agency_account.ga_name).to eq 'NEW AGENCY PROFILE'
        end

        it 'should not get legal name for general agency' do
          expect(general_agency_account.ga_name).not_to eq 'General Agency Profile'
        end

        it 'should not get the cached name for benefit sponsor general agency profile' do
          expect(general_agency_account.ga_name).not_to eq 'OLD AGENCY PROFILE'
        end
      end

      context 'without general-agency-name cached' do
        before do
          Rails.cache.clear
        end

        it 'should get legal name for general agency' do
          expect(general_agency_account.ga_name).to eq general_agency.legal_name
        end
      end
    end
  end
end

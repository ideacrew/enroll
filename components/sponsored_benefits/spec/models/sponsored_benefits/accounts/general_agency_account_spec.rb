# frozen_string_literal: true

require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Accounts::GeneralAgencyAccount, type: :model, dbclean: :after_each do

    let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site, legal_name: "NEW AGENCY PROFILE") }
    let(:general_agency_profile) { general_agency.profiles.first }
    let(:general_agency_account) { FactoryBot.build(:sponsored_benefits_accounts_general_agency_account, general_agency_profile: general_agency_profile, general_agency_profile_id: 'general_agency_profile_id')}

    context "#ga_name" do

      it "should get legal name for general agency" do
        expect(general_agency_account.ga_name).to eq general_agency_profile.legal_name
      end
    end
  end
end

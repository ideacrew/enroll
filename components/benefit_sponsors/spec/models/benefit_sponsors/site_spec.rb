require 'rails_helper'

module BenefitSponsors
  RSpec.describe Site, type: :model, dbclean: :after_each do

    let(:site_key)            { :usa }
    let(:long_name)           { "ACME Widget's Benefit Website" }
    let(:short_name)          { "Benefit Website" }
    let(:domain_name)         { "hbxshop.org" }
    let(:benefit_market_kind) { :aca_shop }
    let(:entity_kind)         { :s_corporation }

    let(:owner_legal_name)    { "ACME Widgets" }
    let(:owner_organization)  { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: owner_legal_name, entity_kind: entity_kind, profiles: [profile]) }
    let(:address)             { BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    let(:phone  )             { BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:office_location)     { BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone) }
    let(:office_locations)    { [office_location] }
    let(:profile)             { FactoryGirl.build(:benefit_sponsors_organizations_hbx_profile, office_locations: office_locations) }

    let(:benefit_market)      { FactoryGirl.build(:benefit_markets_benefit_market, kind: benefit_market_kind) }


    let(:params) do
      {
        site_key: site_key,
        long_name: long_name,
        short_name: short_name,
        domain_name: domain_name,
        owner_organization: owner_organization,
        benefit_markets: [benefit_market]
      }
    end

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        let(:site)  { Site.new }

        it "should not be valid" do
          site.validate
          expect(site).to_not be_valid
        end
      end

      context "with no site_key" do
        let(:site)  { Site.new(params.except(:site_key)) }

        it "should not be valid" do
          site.validate
          expect(site).to_not be_valid
        end
      end

      context "with no owner_organization" do
        let(:site)   { Site.new(params.except(:owner_organization)) }

        it "should not be valid" do
          site.validate
          expect(site).to_not be_valid
        end
      end

      context "with two benefit markets of the same kind", dbclean: :after_each do
        let(:same_benefit_market)      { FactoryGirl.build(:benefit_markets_benefit_market, kind: benefit_market_kind) }

        let(:site) { Site.new(params) }

        before { site.benefit_markets << same_benefit_market }

        it "should not be valid" do
          site.validate
          expect(site).to_not be_valid
          expect(site.errors[:benefit_markets].first).to match(/cannot be more than one/)
        end
      end

      context "with all required arguments", dbclean: :after_each do
        let(:valid_site) { Site.new(params) }

        before do
          valid_site.byline = 'test'
          valid_site.long_name = long_name
          valid_site.short_name = short_name
          valid_site.domain_name = domain_name
          valid_site.owner_organization = owner_organization
          valid_site.site_organizations << owner_organization
        end

        it "should be valid" do
          valid_site.validate
          expect(valid_site).to be_valid
        end

        it "all provided attributes should be set" do
          expect(valid_site.site_key).to eq site_key
          expect(valid_site.owner_organization).to eq owner_organization
          expect(valid_site.long_name).to eq long_name
          expect(valid_site.short_name).to eq short_name
          expect(valid_site.domain_name).to eq domain_name
        end

        context "and record is persisted" do
          before { valid_site.save }

          it "should be findable by site_key" do
            expect(BenefitSponsors::Site.by_site_key(site_key).size).to eq 1
          end
        end
      end
    end

    context "site keys must be valid" do
      let(:site) { FactoryGirl.build(:benefit_sponsors_site) }

      context "with keys longer than max length" do
        let(:max_key_length)  { 6 }
        let(:long_key)        { :excessive_key_lengths_are_invalid }

        it "it should truncate to max length" do
          site.site_key = long_key
          expect(site.site_key).to eq long_key.slice(0, max_key_length).to_sym
        end
      end

      context "with keys of string type" do
        let(:string_key) { "mykey" }

        it "should transform to a symbol" do
          site.site_key = string_key
          expect(site.site_key).to eq string_key.to_sym
        end

      end

      context "with keys that start with numbers" do
        let(:numeric_key) { "12days" }

        it "should strip the leading numbers" do
          site.site_key = numeric_key
          expect(site.site_key).to eq "days".to_sym
        end
      end

      context "with keys with special characters" do
        let(:funky_key) { "m-yK&e*(y#" }

        it "should strip the leading numbers" do
          site.site_key = funky_key
          expect(site.site_key).to eq "mykey".to_sym
        end
      end

      context "with duplicate keys" do
        let(:site_key)  { :mykey }

        it "should reject duplicate key"
      end
    end

    context "organization associations must be valid", dbclean: :after_each do

      let(:owner_legal_name)    { "Hannah Barbara, LLC" }
      let(:loony_legal_name)    { "Loony Tunes, LLC" }
      let(:itune_legal_name)    { "iTunes, Inc" }

      let!(:site)               { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:owner_organization)  { site.owner_organization }
      let(:hbx_profile)         { FactoryGirl.create(:benefit_sponsors_organizations_hbx_profile, organization: owner_organization) }

      let!(:loony_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, legal_name: loony_legal_name, site: site) }
      let!(:acme_organization)  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, legal_name: itune_legal_name, site: site) }

      # this will include the owner_organization in the count
      it "should have correct number of site_organizations" do
        expect((site.site_organizations).size).to eq 3
      end

      it "should have correct number of employer_profiles" do
        expect((site.site_organizations.employer_profiles).size).to eq 2
      end

      context "and benefit_market associations must be valid" do
        let(:profile)             { loony_organization.employer_profile }
        let(:benefit_sponsorship) { profile.add_benefit_sponsorship }

        it "assigned benefit market should be associated with site" do
          expect(benefit_sponsorship.benefit_market).to eq site.benefit_markets.first
        end

        it "site should be valid" do
          expect(site).to be_valid
        end

        context "benefit_market should be findable by kind" do
          let(:shop_kind)             { :aca_shop }
          let(:individual_kind)       { :aca_individual }
          let(:legal_name_1)          { "3M, Corp" }
          let(:legal_name_2)          { "M&M, Corp" }
          let(:legal_name_3)          { "R&D, Corp" }

          let(:shop_benefit_market_1) { FactoryGirl.build(:benefit_markets_benefit_market, kind: shop_kind) }
          let(:shop_benefit_market_2) { FactoryGirl.build(:benefit_markets_benefit_market, kind: shop_kind) }
          let(:ivl_benefit_market_1)  { FactoryGirl.build(:benefit_markets_benefit_market, kind: individual_kind) }
          let(:ivl_benefit_market_2)  { FactoryGirl.build(:benefit_markets_benefit_market, kind: individual_kind) }

          let!(:shop_only_site)       { create(:benefit_sponsors_site, :as_hbx_profile, :cca, benefit_markets: [shop_benefit_market_1]) }
          let!(:ivl_only_site)        { create(:benefit_sponsors_site, :as_hbx_profile, :cca, benefit_markets: [ivl_benefit_market_1]) }
          let!(:shop_and_ivl_site)    { create(:benefit_sponsors_site, :as_hbx_profile, :cca, benefit_markets: [ivl_benefit_market_2, shop_benefit_market_2]) }

          let(:owner_organization_1)  { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, legal_name: legal_name_1, profiles: [hbx_profile], site: shop_only_site) }
          let(:owner_organization_2)  { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, legal_name: legal_name_2, site: ivl_only_site) }
          let(:owner_organization_3)  { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, legal_name: legal_name_3, site: shop_and_ivl_site) }

          it "should find the right benefit_markets using benefit_market_for" do
            expect(shop_only_site.benefit_market_for(shop_kind)).to eq shop_benefit_market_1
            expect(shop_only_site.benefit_market_for(individual_kind)).to be_nil

            expect(ivl_only_site.benefit_market_for(shop_kind)).to be_nil
            expect(shop_and_ivl_site.benefit_market_for(shop_kind)).to eq shop_benefit_market_2

            expect(ivl_only_site.benefit_market_for(individual_kind)).to eq ivl_benefit_market_1
            expect(shop_and_ivl_site.benefit_market_for(individual_kind)).to eq ivl_benefit_market_2
          end
        end


      end

    end

  end
end

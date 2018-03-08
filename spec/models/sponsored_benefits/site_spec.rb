require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Site, type: :model, dbclean: :around_each do
    let(:site) { Site.new }

    let(:site_key)            { :acme }
    let(:owner_legal_name)    { "ACME Widgets" }
    let(:long_name)           { "ACME Widget's Benefit Website" }
    let(:short_name)          { "Benefit Website" }
    let(:domain_name)         { "hbxshop.org" }

    let(:office_location)     { ::Address.new(kind: "primary", address_1: "101 Main St, NW", city: "Washington", state: "DC", zip: "20002") }
    let(:owner_organization)  { FactoryGirl.build(:sponsored_benefits_organizations_exempt_organization, legal_name: owner_legal_name, site: site, site_owner: site) }

    let(:params) do
      {
        site_key: site_key,
        owner_organization: owner_organization,
        long_name: long_name,
        short_name: short_name,
        domain_name: domain_name,
      }
    end

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no site_key" do
        subject { described_class.new(params.except(:site_key)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no owner_organization" do
        subject { described_class.new(params.except(:owner_organization)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        let(:valid_site) { described_class.new(params) }

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
            expect(SponsoredBenefits::Site.find_by_site_key(site_key).size).to eq 1
          end
        end
      end
    end

    context "site keys must be valid" do
      let(:site) { FactoryGirl.build(:sponsored_benefits_site, :with_owner_exempt_organization, site_key: site_key) }

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

    context "organization associations must be valid" do

      let(:owner_legal_name)    { "Hannah Barbara, LLC" }
      let(:loony_legal_name)    { "Loony Tunes, LLC" }
      let(:acme_legal_name)     { "iTunes, Inc" }

      let(:site)                { FactoryGirl.create(:sponsored_benefits_site, :with_owner_exempt_organization) }
      let!(:loony_organization) { FactoryGirl.create(:sponsored_benefits_organizations_general_organization, :with_aca_shop_dc_employer_profile, legal_name: loony_legal_name, site: site) }
      let!(:acme_organization)  { FactoryGirl.create(:sponsored_benefits_organizations_general_organization, :with_aca_shop_dc_employer_profile, legal_name: acme_legal_name, site: site) }


      # this will include the owner_organization in the count
      it "should have correct number of site_organizations" do
        expect((site.site_organizations).size).to eq 3
      end

      it "should have correct number of employer_profiles" do
        expect((site.site_organizations.employer_profiles).size).to eq 2
      end
    end

    context "benefit_market associations must be valid" do
      let(:site)                { FactoryGirl.build(:sponsored_benefits_site, :with_owner_exempt_organization, benefit_markets: [benefit_market]) }
      let(:benefit_market)      { FactoryGirl.build(:sponsored_benefits_benefit_markets_benefit_market, :with_benefit_catalog) }

      it "assigned benefit market should be associated with site" do
        expect(site.benefit_markets.first).to eq benefit_market
      end

      it "and site should be valid" do
        site.validate
        expect(site).to be_valid
      end
    end

  end
end

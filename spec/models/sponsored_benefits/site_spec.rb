require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Site, type: :model, dbclean: :after_each do
    let(:subject) { Site.new }

    let(:site_id)     { "usa" }
    let(:long_name)   { "ACME Widget's Benefit Website" }
    let(:short_name)  { "Benefit Website" }
    let(:domain_name) { "hbxshop.org" }

    let(:office_location)     { ::Address.new(kind: "primary", address_1: "101 Main St, NW", city: "Washington", state: "DC", zip: "20002") }
    let(:owner_organization)  { SponsoredBenefits::Organizations::GeneralOrganization.new(legal_name: "ACME Widgets", fein: "012345678") }
    let(:employer_profile)    { SponsoredBenefits::Organizations::AcaShopDcEmployerProfile.new(organization: owner_organization, office_locations: [office_location]) }

    let(:params) do
      {
        site_id: site_id,
        owner_organization: owner_organization,
        long_name: long_name,
        short_name: short_name,
        domain_name: domain_name,
      }
    end

    context "with no arguments" do
      subject { described_class.new }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with no site_id" do
      subject { described_class.new(params.except(:site_id)) }

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
      subject { described_class.new(params) }

      it "should be valid" do
        subject.validate
        expect(subject).to be_valid
      end
    end

  end
end

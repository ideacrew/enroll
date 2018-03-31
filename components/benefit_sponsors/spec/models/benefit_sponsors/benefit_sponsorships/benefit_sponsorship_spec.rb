require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model do

    let(:site)                      { BenefitSponsors::Site.new(site_key: :dc) }
    let(:organization)              { BenefitSponsors::Organizations::GeneralOrganization.new(legal_name: "DC", fein: 123456789, site: site, profiles: [sponsorship_profile])}
    let(:sponsorship_profile)       { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }
    let(:benefit_market)            { BenefitMarkets::BenefitMarket.new(:kind => :aca_shop, title: "DC Health SHOP", site: site) }
    let(:contact_method)            { :paper_and_electronic }


    let(:params) do 
      {
        organization: organization,
        benefit_market: benefit_market,
        sponsorship_profile: sponsorship_profile,
        contact_method: contact_method,
      }
    end

    context "A new model instance" do
      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no organization" do
        subject { described_class.new(params.except(:organization)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no benefit market" do
        subject { described_class.new(params.except(:benefit_market)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no open sponsorship_profile" do
        subject { described_class.new(params.except(:sponsorship_profile)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no open contact_method" do
        subject { described_class.new(params.except(:contact_method)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }

        context "and contact method is invalid" do
          let(:invalid_contact_method)  { :snapchat }

          before { subject.contact_method = invalid_contact_method }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
          end
        end

        context "and all arguments are valid" do
          it "should reference the correct sponsorship_profile_id" do
            expect(subject.sponsorship_profile_id).to eq sponsorship_profile.id
          end

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end
        end
      end
    end

 
  end
end

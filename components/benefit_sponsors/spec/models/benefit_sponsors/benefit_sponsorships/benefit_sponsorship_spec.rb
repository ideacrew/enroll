require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model do

    let(:benefit_market)            { ::BenefitMarkets::BenefitMarket.new(kind: :aca_shop, title: "DC Health SHOP") }
    let(:site)                      { BenefitSponsors::Site.new(site_key: :dc, benefit_markets: [benefit_market]) }
    let(:organization)              { BenefitSponsors::Organizations::GeneralOrganization.new(site: site, fein: 123456789, legal_name: "DC")}
    let(:profile)                   { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new(organization: organization) }

    let(:params) do
      {
        benefit_market: benefit_market,
        organization: organization,
        profile: profile,
      }
    end

    context "A new model instance" do
       it { is_expected.to be_mongoid_document }
       it { is_expected.to have_fields(:hbx_id, :profile_id)}
       it { is_expected.to have_field(:origin_kind).of_type(Symbol).with_default_value_of(:self_serve)}
       it { is_expected.to embed_many(:broker_agency_accounts)}
       it { is_expected.to belong_to(:organization).as_inverse_of(:benefit_sponorships)}

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

      context "with no profile" do
        subject { described_class.new(params.except(:profile)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      # Contact method set by default in the model
      context "with no contact_method" do
        subject { described_class.new(params.except(:contact_method)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to be_valid
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
          it "should reference the correct profile_id" do
            expect(subject.profile_id).to eq profile.id
          end

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end
        end
      end
    end

    describe "Working around validating model factory" do
      context "when benefit sponsor has profile and organization" do
        let(:benefit_sponsorships) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
        let(:valid_build_benefit_sponsorships) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
        let(:valid_create_benefit_sponsorships) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}

        it "should be validate" do
          expect(benefit_sponsorships.valid?).to be_falsy
          expect(valid_build_benefit_sponsorships.valid?).to be_truthy
          expect(valid_create_benefit_sponsorships.valid?).to be_truthy
        end
      end
    end

    context "Working with subclassed parent Profiles" do
      context "using sic_code helper method" do
        let(:sic_code)                  { "1110" }
        let(:profile_with_sic_code)     { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(sic_code: sic_code ) }
        let(:profile_with_nil_sic_code) { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new }
        let(:profile_without_sic_code)  { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }

        context "on profile without attribute defined" do
          subject { described_class.new(profile: profile_without_sic_code) }

          it "should not return value" do
            expect(subject.sic_code).to be_nil
          end
        end

        context "on profile with attribute defined but not set" do
          subject { described_class.new(profile: profile_with_nil_sic_code) }

          it "should return correct value" do
            expect(subject.sic_code).to be_nil
          end
        end

        context "on profile with attribute defined" do
          subject { described_class.new(profile: profile_with_sic_code) }

          it "should return correct value" do
            expect(subject.sic_code).to eq sic_code
          end
        end
      end

      # TODO: Before deleting this make sure you move this spec to appropriate model
      # context "using rating_area helper method" do
      #   let(:rating_area)                   { ::BenefitMarkets::Locations::RatingArea.new }
      #   let(:profile_with_rating_area)      { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(rating_area: rating_area ) }
      #   let(:profile_with_nil_rating_area)  { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new }
      #   let(:profile_without_rating_area)   { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }

      #   context "on profile without attribute defined" do
      #     subject { described_class.new(profile: profile_without_rating_area) }

      #     it "should not return value" do
      #       expect(subject.rating_area).to be_nil
      #     end
      #   end

      #   context "on profile with attribute defined but not set" do
      #     subject { described_class.new(profile: profile_with_nil_rating_area) }

      #     it "should return correct value" do
      #       expect(subject.rating_area).to be_nil
      #     end
      #   end

      #   context "on profile with attribute defined" do
      #     subject { described_class.new(profile: profile_with_rating_area) }

      #     it "should return correct value" do
      #       expect(subject.rating_area).to eq rating_area
      #     end
      #   end

      # end
    end
  end
end

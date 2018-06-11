require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model do

    let(:site)            { create(:benefit_sponsors_site, :with_owner_exempt_organization, :cca, :with_benefit_market) }
    let(:organization)    { build(:benefit_sponsors_organizations_general_organization, site: site)}
    let(:profile)         { build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, organization: organization) }
    let(:benefit_market)  { site.benefit_markets.first }
    let(:service_areas)   { ::BenefitMarkets::Locations::ServiceArea.service_areas_for(profile.primary_office_location.address) }

    let(:params) do
      {
        benefit_market: benefit_market,
        organization: organization,
        profile: profile,
        service_areas: service_areas
      }
    end

    context "A new model instance" do
      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_fields(:hbx_id, :profile_id)}
      it { is_expected.to have_field(:source_kind).of_type(Symbol).with_default_value_of(:self_serve)}
      it { is_expected.to embed_many(:broker_agency_accounts)}
      it { is_expected.to belong_to(:organization).as_inverse_of(:benefit_sponsorships)}

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

      context "with all required arguments" do
        subject { described_class.new(params) }


        context "and all arguments are valid" do
          it "should reference the correct profile_id" do
            expect(subject.profile_id).to eq profile.id
          end

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should be findable" do
            subject.save!
            expect(described_class.find(subject.id)).to eq subject
          end
        end
      end
    end

    describe "Working around validating model factory" do
      context "when benefit sponsor has profile and organization" do
        let(:benefit_sponsorships) { FactoryGirl.build_stubbed(:benefit_sponsors_benefit_sponsorship)}
        let(:valid_build_benefit_sponsorships) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
        let(:valid_create_benefit_sponsorships) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}

        it "should be valid", :aggregate_failures do
          expect(benefit_sponsorships.valid?).to be_falsy
          expect(valid_build_benefit_sponsorships.valid?).to be_truthy
          expect(valid_create_benefit_sponsorships.valid?).to be_truthy
        end
      end

      context "when benefit sponsorship is CCA SHOP employer" do
        let(:benefit_sponsorship)   { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile) }

        it "should be valid" do
          expect(benefit_sponsorship.valid?).to be true
        end

      end
    end


    describe "Finding a BenefitSponsorCatalog" do
      let(:next_year)                           { Date.today.year + 1 }
      let(:application_period_next_year)        { (Date.new(next_year,1,1))..(Date.new(next_year,12,31)) }
      let(:benefit_sponsorship)                 { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, profile: profile, benefit_market: benefit_market) }
      let!(:benefit_market_catalog_next_year)   { FactoryGirl.build(:benefit_markets_benefit_market_catalog, benefit_market: nil, application_period: application_period_next_year) }
      # let(:benefit_market_catalog_future_year)  { FactoryGirl.build(:benefit_markets_benefit_market_catalog, benefit_market: nil, application_period: application_period) }

      before { benefit_market.add_benefit_market_catalog(benefit_market_catalog_next_year) }

      it "should belong to the same site and benefit_market and include benefit_market_catalog_next_year", :aggregate_failures do
        expect(benefit_sponsorship.profile.organization.site).to eq benefit_market.site
        expect(benefit_sponsorship.benefit_market).to eq benefit_market
        expect(benefit_market.benefit_market_catalogs.size).to eq 1
        expect(benefit_market.benefit_market_catalogs.first).to eq benefit_market_catalog_next_year
      end

      context "given an effective_date during next year's application period" do
        let(:effective_date)  { benefit_market.benefit_market_catalogs.first.application_period.min }

        # before { benefit_market.benefit_market_catalogs = benefit_market_catalogs }
        it "should find a benefit_market_catalog" do
          # binding.pry
          expect(benefit_sponsorship.benefit_sponsor_catalog_for(effective_date)).to be_an_instance_of(BenefitMarkets::BenefitSponsorCatalog)
        end
      end

      context "given an effective_date in future, undefined application period" do
        let(:future_effective_date)  { Date.new((next_year + 2),1,1) }

        it "should not find a benefit_market_catalog" do
          expect{benefit_sponsorship.benefit_sponsor_catalog_for(future_effective_date)}.to raise_error(/benefit_market_catalog not found for effective date: #{future_effective_date}/)
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

    describe "Transitioning a BenefitSponsorship through workflow states" do
      let(:benefit_sponsorship)     { described_class.new(**params) }
      let(:effective_date)          { Date.today.beginning_of_month }
      let(:benefit_application)     { build(:benefit_sponsors_benefit_application,
                                                :with_benefit_sponsor_catalog,
                                                effective_period: effective_date..(effective_date + 1.year - 1.day),
                                                benefit_sponsorship: benefit_sponsorship,
                                                recorded_service_areas: benefit_sponsorship.service_areas) }

      context "Initial application happy path workflow" do
        before {
                    organization.benefit_sponsorships << benefit_sponsorship
                    TimeKeeper.set_date_of_record_unprotected!(Date.today)
                  }

        it "should initialize in state: :applicant" do
          binding.pry
          expect(benefit_sponsorship.aasm_state).to eq :applicant
        end

        context "and a valid benefit application is submitted" do
          before { benefit_application.approve_application! }

          it "benefit_sponsorship should transition to state: :initial_application_approved" do
            expect(benefit_sponsorship.aasm_state).to eq :initial_application_approved
          end

          context "and open enrollment period begins" do
            before {
                TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.min)
                benefit_application.begin_open_enrollment!
              }

            it "should transition to state: :initial_enrollment_open" do
              expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
            end

            context "and open enrollment period ends" do
              before {
                  TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.max)
                  benefit_application.end_open_enrollment!
                }

              it "benefit_sponsorship should transition to state: :initial_enrollment_closed" do
                expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_closed
              end

              context "and binder payment is made" do
                before { benefit_sponsorship.credit_binder! }

                it "benefit_sponsorship should transition to state: :initial_enrollment_eligible" do
                  expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_eligible
                end

                it "benefit_application should transition to state: :enrollment_eligible" do
                  expect(benefit_application.aasm_state).to eq :enrollment_eligible
                end

                context "and effective period begins" do
                  before {
                      TimeKeeper.set_date_of_record_unprotected!(benefit_application.effective_period.min)
                      benefit_application.activate_enrollment!
                    }

                  it "benefit_sponsorship should transition to state: :active" do
                    expect(benefit_sponsorship.aasm_state).to eq :active
                  end

                  it "benefit_application should transition to state: :active" do
                    expect(benefit_application.aasm_state).to eq :active
                  end
                end
              end
            end
          end
        end
      end

    end


  end
end

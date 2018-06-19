require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model do

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:employer_organization)   { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }

    context "A new model instance" do
      subject { employer_profile.add_benefit_sponsorship }

      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_fields(:hbx_id, :profile_id)}
      it { is_expected.to have_field(:source_kind).of_type(Symbol).with_default_value_of(:self_serve)}
      it { is_expected.to embed_many(:broker_agency_accounts)}
      it { is_expected.to belong_to(:organization).as_inverse_of(:benefit_sponsorships)}

      context "with all required arguments" do

        context "and all arguments are valid" do
          it "should reference the correct profile_id" do
            expect(subject.profile_id).to eq employer_profile.id
          end

          it "should reference a rating_area" do
            expect(subject.rating_area).to be_an_instance_of(::BenefitMarkets::Locations::RatingArea)
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
        let(:valid_build_benefit_sponsorship)  { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
        let(:valid_create_benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}

        it "with_full_package build should be valid" do
          # binding.pry
          expect(valid_build_benefit_sponsorship.valid?).to be_truthy
        end

        it "with_market_profile create should be valid" do
          binding.pry
          expect(valid_create_benefit_sponsorship.valid?).to be_truthy
        end
      end

      context "when benefit sponsorship is CCA SHOP employer" do
        let(:cca_profile)         { FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site)  }
        let(:benefit_sponsorship) { cca_profile.add_benefit_sponsorship }

        it "should be valid" do
          expect(benefit_sponsorship.valid?).to be true
        end

      end
    end

    describe "Finding a BenefitSponsorCatalog" do
      let(:benefit_sponsorship)                 { employer_profile.add_benefit_sponsorship }
      let(:next_year)                           { Date.today.year + 1 }
      let(:application_period_next_year)        { (Date.new(next_year,1,1))..(Date.new(next_year,12,31)) }
      let!(:benefit_market_catalog_next_year)   { FactoryGirl.build(:benefit_markets_benefit_market_catalog, benefit_market: nil, application_period: application_period_next_year) }

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
        let(:cca_employer_organization)   { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:cca_employer_profile)        { cca_employer_organization.employer_profile }
        let(:sic_code)                    { "1110" }

        context "on cca_employer_profile with attribute defined but not set" do
          before { cca_employer_profile.sic_code = nil; cca_employer_profile.add_benefit_sponsorship }

          it "cca_employer_profile should have exactly one benefit_sponsorship" do
            expect(cca_employer_profile.benefit_sponsorships.size).to eq 1
          end

          it "empployer_profile sic_code should be set" do
            expect(cca_employer_profile.sic_code).to eq nil
          end

          it "should return correct value" do
            expect(cca_employer_profile.benefit_sponsorships[0].sic_code).to be_nil
          end
        end

        context "on cca_employer_profile with attribute defined" do
          before { cca_employer_profile.sic_code = sic_code; cca_employer_profile.add_benefit_sponsorship }

          it "should return correct value" do
            expect(cca_employer_profile.benefit_sponsorships[0].sic_code).to eq sic_code
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

    describe "Transitioning a BenefitSponsorship through Initial Application Workflow States" do
      let(:benefit_sponsorship)                 { employer_profile.add_benefit_sponsorship }
      let(:this_year)                           { Date.today.year }
      let(:benefit_application)                 { build(:benefit_sponsors_benefit_application,
                                                        benefit_sponsorship: benefit_sponsorship,
                                                        recorded_service_areas: benefit_sponsorship.service_areas) }

      context "and system date is set to today" do
        before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

        it "benefit_sponsorship should initialize in state: :applicant" do
          expect(benefit_sponsorship.aasm_state).to eq :applicant
        end

        it "benefit_application should initialize in state: :draft" do
          expect(benefit_application.aasm_state).to eq :draft
        end

        context "and a benefit application is submitted" do
          context "and benefit application is valid" do
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

                context "and binder payment is credited" do
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

                  context "and binder payment is reversed" do
                    before { benefit_sponsorship.reverse_binder! }

                    it "benefit_sponsorship should transition to state: :initial_enrollment_closed" do
                      expect(benefit_sponsorship.aasm_state).to eq :binder_reversed
                    end

                    it "benefit_application should transition to state: enrollment_closed" do
                      expect(benefit_application.aasm_state).to eq :enrollment_closed
                    end

                    context "and effective period begins" do
                      before {
                        TimeKeeper.set_date_of_record_unprotected!(benefit_application.effective_period.min)
                        benefit_application.activate_enrollment!
                      }

                      it "benefit_sponsorship should transition to state: :applicant" do
                        expect(benefit_sponsorship.aasm_state).to eq :applicant
                      end

                      it "benefit_application should transition to state: :expired" do
                        expect(benefit_application.aasm_state).to eq :expired
                      end
                    end
                  end
                end
              end
            end
          end

          context "and benefit application is invalid" do
            before { benefit_application.review_application! }

            it "benefit_application should transition to state: :pending" do
              expect(benefit_application.aasm_state).to eq :pending
            end

            it "benefit_sponsorship should transition to state: :initial_application_under_review" do
              expect(benefit_sponsorship.aasm_state).to eq :initial_application_under_review
            end

            context "and it's denied by HBX" do
              before { benefit_application.deny_application! }

              it "benefit_application should transition to state: :denied" do
                expect(benefit_application.aasm_state).to eq :denied
              end

              it "benefit_sponsorship should transition to state: :initial_application_denied" do
                expect(benefit_sponsorship.aasm_state).to eq :initial_application_denied
              end
            end

            context "and it's approved by HBX" do
              before { benefit_application.approve_application! }

              it "benefit_application should transition to state: :approved" do
                expect(benefit_application.aasm_state).to eq :approved
              end

              it "benefit_sponsorship should transition to state: :initial_application_approved" do
                expect(benefit_sponsorship.aasm_state).to eq :initial_application_approved
              end
            end

            context "and it's reverted by HBX" do
              before { benefit_application.revert_application }

              it "benefit_application should transition to state: :draft" do
                expect(benefit_application.aasm_state).to eq :draft
              end

              it "benefit_sponsorship should transition to state: :applicant" do
                expect(benefit_sponsorship.aasm_state).to eq :applicant
              end
            end
          end
        end
      end
    end
  end
end

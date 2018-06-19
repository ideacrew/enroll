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
        end
      end
    end

    describe "Working around validating model factory" do
      context "when benefit sponsor has profile and organization" do
        let(:benefit_sponsorships) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
        let(:valid_build_benefit_sponsorships) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
        let(:valid_create_benefit_sponsorships) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}

        it "should be valid" do
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
      let(:benefit_application)     { build(:benefit_sponsors_benefit_application,
                                                :with_benefit_sponsor_catalog,
                                                benefit_sponsorship: benefit_sponsorship,
                                                recorded_service_areas: benefit_sponsorship.service_areas) }

      context "Initial application happy path workflow" do
        before {
                    organization.benefit_sponsorships << benefit_sponsorship
                    TimeKeeper.set_date_of_record_unprotected!(Date.today)
                  }

        it "should initialize in state: :applicant" do
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

    describe "Scopes", :dbclean => :after_each do
      let(:this_year)                       { TimeKeeper.date_of_record.year }
      
      let(:march_effective_date)            { Date.new(this_year,3,1) }
      let(:march_open_enrollment_begin_on)  { march_effective_date - 1.month }
      let(:march_open_enrollment_end_on)    { march_open_enrollment_begin_on + 9.days }
      
      let(:april_effective_date)            { Date.new(this_year,4,1) }
      let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
      let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

      let(:initial_application_state)       { :active }
      let(:renewal_application_state)       { :enrollment_open }

      let!(:march_sponsors)                 { create_list(:benefit_sponsors_benefit_sponsorship, 3, :with_organization_cca_profile, 
        :with_initial_benefit_application, initial_application_state: initial_application_state, 
        default_effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)))
      }

      let!(:april_sponsors)                 { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile, 
        :with_initial_benefit_application, initial_application_state: initial_application_state, 
        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)))
      }

      let!(:april_renewal_sponsors)         { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile, 
        :with_renewal_benefit_application, initial_application_state: initial_application_state,
        renewal_application_state: renewal_application_state,
        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)))
      }

      before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

      subject { BenefitSponsors::BenefitSponsorships::BenefitSponsorship }

      context '.may_begin_open_enrollment?' do
        let(:initial_application_state) { :approved }

        it "should find sponsorships with application in approved state and matching open enrollment begin date" do
          expect(subject.may_begin_open_enrollment?(april_open_enrollment_begin_on).size).to eq (april_sponsors.size)
          expect(subject.may_begin_open_enrollment?(april_open_enrollment_begin_on).to_a).to eq (april_sponsors)
        end
      end

      context '.may_end_open_enrollment?' do
        let(:initial_application_state) { :enrollment_open }
        let(:renewal_application_state) { :enrollment_open }

        it "should find sponsorships with application in enrollment_open state and matching open enrollment end date" do
          expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on).size).to eq (april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on).to_a).to eq (april_sponsors + april_renewal_sponsors)
        end
      end

      context '.may_begin_benefit_coverage?' do 
        let(:initial_application_state) { :enrollment_eligible }
        let(:renewal_application_state) { :enrollment_eligible }

        it "should find sponsorships with application in enrollment_eligible state and matching effective period begin date" do
          expect(subject.may_begin_benefit_coverage?(march_effective_date).size).to eq (march_sponsors.size)
          expect(subject.may_begin_benefit_coverage?(march_effective_date).to_a).to eq (march_sponsors)

          expect(subject.may_begin_benefit_coverage?(april_effective_date).size).to eq (april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_begin_benefit_coverage?(april_effective_date).to_a).to eq (april_sponsors + april_renewal_sponsors)
        end
      end

      context '.may_end_benefit_coverage?' do
        let(:initial_application_state) { :active }
        let(:renewal_application_state) { :approved }

        it "should find sponsorships with application in active state and matching effective period end date" do
          expect(subject.may_end_benefit_coverage?(march_effective_date.next_year.prev_day).size).to eq (march_sponsors.size)
          expect(subject.may_end_benefit_coverage?(march_effective_date.next_year.prev_day).to_a).to eq (march_sponsors)

          expect(subject.may_end_benefit_coverage?(april_effective_date.next_year.prev_day).size).to eq (april_sponsors.size)
          expect(subject.may_end_benefit_coverage?(april_effective_date.next_year.prev_day).to_a).to eq (april_sponsors)
        end
      end

      context '.may_renew_application?' do
        let(:initial_application_state) { :active }

        it "should find sponsorships with application in active state and matching effective period begin date" do
          expect(subject.may_renew_application?(april_effective_date.prev_year).size).to eq (april_renewal_sponsors.size)
          expect(subject.may_renew_application?(april_effective_date.prev_year).to_a).to eq (april_renewal_sponsors)
        end
      end

      context '.may_terminate_benefit_coverage?' do

        it "should find sponsorships with application in termination_pending state and matching terminated_on date" do
        end
      end

      context '.may_transmit_initial_enrollment?' do 

      end

      context '.may_auto_submit_application?' do 
      end
    end
  end
end

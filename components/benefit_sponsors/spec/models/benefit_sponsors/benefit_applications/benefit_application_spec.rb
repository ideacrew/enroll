require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplication, type: :model do
    let(:subject) { BenefitApplications::BenefitApplication.new }

    # let(:date_range) { (Date.today..1.year.from_now) }
    let(:profile)                   { BenefitSponsors::Organizations::HbxProfile.new }
    let(:site)                      { BenefitSponsors::Site.new(site_key: :dc) }
    let(:owner_organization)        { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: "DC", fein: 123456789, site: site, profiles: [profile])}
    let(:benefit_market)            { create :benefit_markets_benefit_market, site: site, kind: 'aca_shop' }

    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }


    let(:recorded_service_area)     { ::BenefitMarkets::Locations::ServiceArea.new }
    let(:recorded_rating_area)      { ::BenefitMarkets::Locations::RatingArea.new }

    let(:params) do
      {
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period,
        recorded_service_area:  recorded_service_area,
        recorded_rating_area:   recorded_rating_area,
      }
    end


    context "A new model instance" do
     it { is_expected.to be_mongoid_document }
     it { is_expected.to have_fields(:effective_period, :open_enrollment_period, :terminated_on)}
     it { is_expected.to have_field(:aasm_state).of_type(Symbol).with_default_value_of(:draft)}
     it { is_expected.to have_field(:fte_count).of_type(Integer).with_default_value_of(0)}
     it { is_expected.to have_field(:pte_count).of_type(Integer).with_default_value_of(0)}
     it { is_expected.to have_field(:msp_count).of_type(Integer).with_default_value_of(0)}

     it { is_expected.to embed_many(:benefit_packages)}
     it { is_expected.to belong_to(:successor_application).as_inverse_of(:predecessor_application)}

      before do
        site.owner_organization = owner_organization
        benefit_market.save!
      end

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no effective_period" do
        subject { described_class.new(params.except(:effective_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no open_enrollment_period" do
        subject { described_class.new(params.except(:open_enrollment_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no recorded_service_area" do
        subject { described_class.new(params.except(:recorded_service_area)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no recorded_rating_area" do
        subject { described_class.new(params.except(:recorded_rating_area)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject {described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        context "and it is saved" do

          it "should save" do
            expect(subject.save).to eq true
          end

          context "it should be findable" do
            before { subject.save! }
            it "should return the instance" do
              expect(described_class.find(subject.id.to_s)).to eq subject
            end
          end
        end
      end
    end

    describe "Extending a BenefitApplication's open_enrollment_period" do
      let(:benefit_application)   { described_class.new(**params) }

      context "and the application can transition to open enrollment state" do
        let(:valid_open_enrollment_transition_state)    { :approved }

        before { benefit_application.aasm_state = valid_open_enrollment_transition_state }

        it "transition into open enrollment should be valid" do
          expect(benefit_application.may_begin_open_enrollment?).to eq true
        end

        context "and the new end date is later than effective_period start" do
          let(:late_open_enrollment_end_date)  { effective_period.min + 1.day }

          before do
            benefit_application.extend_open_enrollment_period(late_open_enrollment_end_date)
          end

          it "should not change the open_enrollment_period" do
            expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
          end

          it "should not change the application state" do
            expect(benefit_application.aasm_state).to eq valid_open_enrollment_transition_state
          end
        end

        context "and the new end date is in the past" do
          let(:past_date) { open_enrollment_period_end_on - 1.day }

          before do
            TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period_end_on)
            benefit_application.extend_open_enrollment_period(past_date)
          end

          it "should be able to transition into open enrollment" do
            expect(benefit_application.may_begin_open_enrollment?).to eq true
          end

          it "should not change the open_enrollment_period" do
            expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
          end

          it "should not change the application state" do
            expect(benefit_application.aasm_state).to eq valid_open_enrollment_transition_state
          end
        end

        context "and the new end date is valid" do
          let(:valid_date)  { effective_period_start_on - 1.day }

          before { benefit_application.extend_open_enrollment_period(valid_date) }

          it "should change the open_enrollment_period end date and transition into open_enrollment" do
            expect(benefit_application.open_enrollment_end_on).to eq valid_date
            expect(benefit_application.aasm_state).to eq(:enrollment_open)
          end

          context "and the application cannot transition into open_enrollment_state" do
            let(:invalid_open_enrollment_transition_state)  { :draft }

            before do
              benefit_application.open_enrollment_period = open_enrollment_period
              benefit_application.aasm_state = invalid_open_enrollment_transition_state
              benefit_application.extend_open_enrollment_period(valid_date)
            end

            it "transition into open enrollment should be invalid" do
              expect(benefit_application.may_begin_open_enrollment?).to eq false
            end

            it "should not change the open_enrollment_period or transition into open_enrollment" do
              expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
              expect(benefit_application.aasm_state).to eq(invalid_open_enrollment_transition_state)
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

      let!(:march_sponsors)                 { FactoryGirl.create_list(:benefit_sponsors_benefit_applications, 3,
                                              effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)) )}
      let!(:april_sponsors)                 { FactoryGirl.create_list(:benefit_sponsors_benefit_applications, 2,
                                              effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)) )}

      before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

      it "should find applications by Effective date start" do
        expect(BenefitApplications::BenefitApplication.all.size).to eq 5
        expect(BenefitApplications::BenefitApplication.effective_date_begin_on(march_effective_date).to_a).to eq march_sponsors
        expect(BenefitApplications::BenefitApplication.effective_date_begin_on(april_effective_date).to_a).to eq april_sponsors
      end

      it "should find applications by Open Enrollment begin" do
        expect(BenefitApplications::BenefitApplication.open_enrollment_begin_on(march_open_enrollment_begin_on)).to eq march_sponsors
        expect(BenefitApplications::BenefitApplication.open_enrollment_begin_on(april_open_enrollment_begin_on)).to eq april_sponsors
      end

      it "should find applications by Open Enrollment end" do
        expect(BenefitApplications::BenefitApplication.open_enrollment_end_on(march_open_enrollment_end_on)).to eq march_sponsors
        expect(BenefitApplications::BenefitApplication.open_enrollment_end_on(april_open_enrollment_end_on)).to eq april_sponsors
      end

      it "should find applications in Plan Draft status" do
        expect(BenefitApplications::BenefitApplication.plan_design_draft).to eq march_sponsors + april_sponsors
      end

      it "should find applications with chained scopes" do
        expect(BenefitApplications::BenefitApplication.
                                        plan_design_draft.
                                        open_enrollment_begin_on(april_open_enrollment_begin_on)).to eq april_sponsors
      end

      it "should find applications in Plan Design Exception status"
      it "should find applications in Plan Design Approved status"
      it "should find applications in Enrolling status"
      it "should find applications in Enrollment Eligible status"
      it "should find applications in Enrollment Ineligible status"
      it "should find applications in Coverage Effective status"
      it "should find applications in Terminated status"
      it "should find applications in Expired Effective status"


      context "with an application in renewing status" do
        let(:last_year)                       { this_year - 1 }
        let(:last_march_effective_date)       { Date.new(last_year,3,1) }
        let!(:initial_application)            { FactoryGirl.create(:benefit_sponsors_benefit_applications,
                                                effective_period: (last_march_effective_date..(last_march_effective_date + 1.year - 1.day)) )}
        let!(:renewal_application)            { FactoryGirl.create(:benefit_sponsors_benefit_applications,
                                                effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)),
                                                predecessor_application: initial_application)}

        it "should find the renewing application" do
          expect(BenefitApplications::BenefitApplication.is_renewing).to eq [renewal_application]
        end
      end


    end


    describe "Transitioning a BenefitApplication through Plan Design states" do
      let(:benefit_application)   { described_class.new(**params) }

    end


    describe "Transitioning a BenefitApplication through Enrolling states" do

    end


    ## TODO: Refactor for BenefitApplication
    # context "#to_plan_year", dbclean: :after_each do
    #   let(:benefit_application)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }
    #   let(:benefit_sponsorship)       { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(benefit_market: :aca_shop_cca) }

    #   let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    #   let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    #   let(:office_location) { OfficeLocation.new(
    #       is_primary: true,
    #       address: address,
    #       phone: phone
    #     )
    #   }

    #   let(:plan_design_organization)  { BenefitSponsors::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc") }
    #   let(:plan_design_proposal)      { BenefitSponsors::Organizations::PlanDesignProposal.new(title: "New Proposal") }
    #   let(:profile) {BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new}

    #   before(:each) do
    #     plan_design_organization.plan_design_proposals << [plan_design_proposal]
    #     plan_design_proposal.profile = profile
    #     profile.organization.benefit_sponsorships = [benefit_sponsorship]
    #     benefit_sponsorship.benefit_applications  = [benefit_application]
    #     benefit_application.benefit_packages.build
    #     plan_design_organization.save
    #   end

    #   it "should instantiate a plan year object and must have correct values assigned" do
    #     plan_year = benefit_application.to_plan_year
    #     expect(plan_year.class).to eq PlanYear
    #     expect(plan_year.benefit_groups.present?).to eq true
    #     expect(plan_year.start_on).to eq benefit_application.effective_period.begin
    #     expect(plan_year.end_on).to eq benefit_application.effective_period.end
    #     expect(plan_year.open_enrollment_start_on).to eq benefit_application.open_enrollment_period.begin
    #     expect(plan_year.open_enrollment_end_on).to eq benefit_application.open_enrollment_period.end
    #   end
    # end

    context "a BenefitApplication class" do
      let(:subject)             { BenefitApplications::BenefitApplicationSchedular.new }
      let(:begin_day)           { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                  Settings.aca.shop_market.open_enrollment.minimum_length.adv_days }
      let(:grace_begin_day)     { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                  Settings.aca.shop_market.open_enrollment.minimum_length.days }

      def standard_begin_day
        (begin_day > 0) ? begin_day : 1
      end

      it "should return the day of month deadline for an open enrollment standard period to begin" do
        expect(subject.open_enrollment_minimum_begin_day_of_month).to eq standard_begin_day
      end

      it "should return the day of month deadline for an open enrollment grace period to begin" do
        expect(subject.open_enrollment_minimum_begin_day_of_month(true)).to eq grace_begin_day
      end

      context "and a calendar date is passed to effective period by date method" do
        let(:seed_date)                         { TimeKeeper.date_of_record + 2.months + 3.days }
        let(:next_month_begin_on)               { seed_date.beginning_of_month + 1.month }
        let(:next_month_effective_period)       { next_month_begin_on..(next_month_begin_on + 1.year - 1.day) }
        let(:following_month_begin_on)          { seed_date.beginning_of_month + 2.months }
        let(:following_month_effective_period)  { following_month_begin_on..(following_month_begin_on + 1.year - 1.day) }

        let(:standard_period_last_day)          { subject.open_enrollment_minimum_begin_day_of_month }
        let(:standard_period_deadline_date)     { Date.new(seed_date.year, seed_date.month, standard_period_last_day) }
        let(:standard_period_pre_deadline_date) { standard_period_deadline_date - 1.day }

        let(:grace_period_last_day)             { subject.open_enrollment_minimum_begin_day_of_month(true) }
        let(:grace_period_deadline_date)        { Date.new(seed_date.year, seed_date.month, grace_period_last_day) }
        let(:grace_period_post_deadline_date)   { grace_period_deadline_date + 1.day }


        context "that is before standard period deadline" do
          it "should provide an effective (standard) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_pre_deadline_date)).to eq next_month_effective_period
          end

          it "should provide an effective (grace) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_pre_deadline_date, true)).to eq next_month_effective_period
          end
        end

        context "that is the same day as the standard period deadline" do
          it "should provide an effective (standard) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_deadline_date)).to eq next_month_effective_period
          end

          it "should provide an effective (grace) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_deadline_date, true)).to eq next_month_effective_period
          end
        end

        # TODO: Open enrollment minimum length setting for days & adv_days same.
        #       Following spec need to be improved to handle this scenario.
        # context "that is after the standard period, but before the grace period deadline" do
        #   it "should provide an effective (standard) period beginning the first of month following next month" do
        #     expect(subject.effective_period_by_date(grace_period_deadline_date)).to eq following_month_effective_period
        #   end

        #   it "should provide an effective (grace) period beginning the of first next month" do
        #     expect(subject.effective_period_by_date(grace_period_deadline_date, true)).to eq next_month_effective_period
        #   end
        # end

        context "that is after both the standard and grace period deadlines" do
          it "should provide an effective (standard) period beginning the first of month following next month" do
            expect(subject.effective_period_by_date(grace_period_post_deadline_date)).to eq following_month_effective_period
          end

          it "should provide an effective (grace) period beginning the first of month following next month" do
            expect(subject.effective_period_by_date(grace_period_post_deadline_date, true)).to eq following_month_effective_period
          end
        end
      end

      context "and an effective date is passed to open enrollment period by effective date method" do
        let(:effective_date)                  { (TimeKeeper.date_of_record + 3.months).beginning_of_month }
        let(:prior_month)                     { effective_date - 1.month }
        let(:valid_open_enrollment_begin_on)  { effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months }
        let(:valid_open_enrollment_end_on)    { Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on) }
        let(:valid_open_enrollment_period)    { valid_open_enrollment_begin_on..valid_open_enrollment_end_on }

        it "should provide a valid open enrollment period for that effective date" do
          expect(subject.open_enrollment_period_by_effective_date(effective_date)).to eq valid_open_enrollment_period
        end
      end

      context "and an effective date is passed to enrollment timetable by effective date method" do
        let(:effective_date)                  { TimeKeeper.date_of_record.next_month.end_of_month + 1.day }

        let(:prior_month)                     { effective_date - 1.month }

        let(:begin_day)                        { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                                Settings.aca.shop_market.open_enrollment.minimum_length.adv_days }

        let(:open_enrollment_end_day)         { Settings.aca.shop_market.open_enrollment.monthly_end_on }
        let(:open_enrollment_end_on)          { Date.new(prior_month.year, prior_month.month, open_enrollment_end_day) }

        let(:late_open_enrollment_begin_on)   { Date.new(prior_month.year, prior_month.month, late_open_enrollment_begin_day) }
        let(:late_open_enrollment_period)     { late_open_enrollment_begin_on..open_enrollment_end_on }

        let(:binder_payment_due_on) {
          Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)
        }

        let(:valid_timetable)                 {
                                                {
                                                    effective_date:                 effective_date,
                                                    effective_period:               effective_date..(effective_date.next_year - 1.day),
                                                    open_enrollment_period:         TimeKeeper.date_of_record..open_enrollment_end_on,
                                                    open_enrollment_period_minimum: late_open_enrollment_period,
                                                    binder_payment_due_on:          binder_payment_due_on
                                                }
                                              }
        def late_open_enrollment_begin_day
          (begin_day > 0) ? begin_day : 1
        end

        it "should provide a valid an enrollment timetabe hash for that effective date" do
          expect(subject.enrollment_timetable_by_effective_date(effective_date)).to eq valid_timetable
        end

        it "timetable date values should be valid" do
          timetable = subject.enrollment_timetable_by_effective_date(effective_date)
          expect(BenefitApplications::BenefitApplication.new(
                              effective_period: timetable[:effective_period],
                              open_enrollment_period: timetable[:open_enrollment_period],
                              recorded_service_area:  recorded_service_area,
                              recorded_rating_area:   recorded_rating_area,
                            )).to be_valid
        end
      end

    end
  end
end

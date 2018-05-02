require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplication, type: :model do
    let(:subject) { BenefitApplications::BenefitApplication.new }

    # let(:date_range) { (Date.today..1.year.from_now) }
    let(:profile)                   { BenefitSponsors::Organizations::HbxProfile.new }
    let(:site)                      { BenefitSponsors::Site.new(site_key: :dc, benefit_markets: [benefit_market]) }
    let(:owner_organization)        { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: "DC", fein: 123456789, site: site, profiles: [profile])}
    let(:benefit_market)            { ::BenefitMarkets::BenefitMarket.new(:kind => :aca_shop, title: "DC Health SHOP") }

    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

    let(:params) do
      {
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period,
      }
    end

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

    context "with no open enrollment period" do
      subject { described_class.new(params.except(:open_enrollment_period)) }

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

    context "#to_plan_year", dbclean: :after_each do
      let(:benefit_application)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }
      let(:benefit_sponsorship)       { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(benefit_market: :aca_shop_cca) }

      let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location) { OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
        )
      }

      let(:plan_design_organization)  { BenefitSponsors::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc") }
      let(:plan_design_proposal)      { BenefitSponsors::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      let(:profile) {BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new}

      before(:each) do
        plan_design_organization.plan_design_proposals << [plan_design_proposal]
        plan_design_proposal.profile = profile
        profile.organization.benefit_sponsorships = [benefit_sponsorship]
        benefit_sponsorship.benefit_applications  = [benefit_application]
        benefit_application.benefit_packages.build
        plan_design_organization.save
      end

      it "should instantiate a plan year object and must have correct values assigned" do
        plan_year = benefit_application.to_plan_year
        expect(plan_year.class).to eq PlanYear
        expect(plan_year.benefit_groups.present?).to eq true
        expect(plan_year.start_on).to eq benefit_application.effective_period.begin
        expect(plan_year.end_on).to eq benefit_application.effective_period.end
        expect(plan_year.open_enrollment_start_on).to eq benefit_application.open_enrollment_period.begin
        expect(plan_year.open_enrollment_end_on).to eq benefit_application.open_enrollment_period.end
      end
    end

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
          expect(BenefitApplications::BenefitApplication.new(effective_period: timetable[:effective_period], open_enrollment_period: timetable[:open_enrollment_period])).to be_valid
        end
      end

    end
  end
end

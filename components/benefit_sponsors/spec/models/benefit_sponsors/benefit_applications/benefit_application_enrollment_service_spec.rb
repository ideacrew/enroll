require 'rails_helper'

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationEnrollmentService, type: :model, :dbclean => :after_each do
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

    let(:market_inception) { TimeKeeper.date_of_record.year }
    let(:current_effective_date) { Date.new(market_inception, 8, 1) }

    include_context "setup benefit market with market catalogs and product packages"

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    describe '.renew' do
      let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
      let(:aasm_state) { :active }
      let(:business_policy) { instance_double("some_policy", success_results: "validated successfully")}
      include_context "setup initial benefit application"

      before(:all) do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
      end

      after(:all) do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

      context "when initial employer eligible for renewal" do

        it "should generate renewal application" do
          allow(subject).to receive(:business_policy).and_return(business_policy)
          allow(business_policy).to receive(:is_satisfied?).with(initial_application).and_return(true)
          subject.renew_application
          benefit_sponsorship.reload

          renewal_application = benefit_sponsorship.benefit_applications.detect{|application| application.is_renewing?}
          expect(renewal_application).not_to be_nil

          expect(renewal_application.start_on.to_date).to eq current_effective_date.next_year
          expect(renewal_application.benefit_sponsor_catalog).not_to be_nil
          expect(renewal_application.benefit_packages.count).to eq 1
        end
      end
    end

    describe '.revert_application' do

    end

    describe '.submit_application' do
      let(:market_inception) { TimeKeeper.date_of_record.year - 1 }

      context "when initial employer present with valid application" do

        let(:open_enrollment_begin) { TimeKeeper.date_of_record - 5.days }

        include_context "setup initial benefit application" do
        let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
        let(:open_enrollment_period) { open_enrollment_begin..(effective_period.min - 10.days) }
        let(:aasm_state) { :draft }
        end

        before(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
        end

        after(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment start date in the past" do

          it "should submit application with immediate open enrollment" do
            subject.submit_application
            initial_application.reload
            expect(initial_application.aasm_state).to eq :enrollment_open
            expect(initial_application.open_enrollment_period.begin.to_date).to eq TimeKeeper.date_of_record
          end
        end

        context "open enrollment start date in the future" do
          let(:open_enrollment_begin) { TimeKeeper.date_of_record + 5.days }

          it "should submit application with approved status" do
            subject.submit_application
            initial_application.reload
            expect(initial_application.aasm_state).to eq :approved
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.force_submit_application' do
      include_context "setup initial benefit application"

      context "renewal application in draft state" do

        let!(:renewal_application)  { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application).renew_application.save! }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(renewal_application) }

        context "today is prior to date for force publish" do
          before(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 7, 15))
          end

          after(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          it "should not change the benefit application" do
            subject.force_submit_application
            expect(renewal_application.aasm_state).to eq :draft
          end

        end

        context "today is date for force publish" do

          before(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 7, 16))
          end

          after(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          it "should transition the benefit_application into :enrollment_open" do
            subject.force_submit_application
            expect(renewal_application.aasm_state).to eq :enrollment_open
          end

          context "the active benefit_application has benefits that can be mapped into renewal benefit_application" do
            it "should autorenew all active members"
          end

          context "the active benefit_application has benefits that Cannot be mapped into renewal benefit_application" do
            it "should not autorenew all active members"
          end

        end
      end


    end

    describe '.begin_open_enrollment' do
      context "when initial employer present with valid approved application" do

        let(:open_enrollment_begin) { TimeKeeper.date_of_record - 5.days }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:open_enrollment_period) { open_enrollment_begin..(effective_period.min - 10.days) }
          let(:aasm_state) { :approved }
        end

        before(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
        end

        after(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment start date in the past" do

          it "should begin open enrollment" do
            subject.begin_open_enrollment
            initial_application.reload
            expect(initial_application.aasm_state).to eq :enrollment_open
          end
        end

        context "open enrollment start date in the future" do
          let(:open_enrollment_begin) { TimeKeeper.date_of_record + 5.days }

          it "should do nothing" do
            subject.begin_open_enrollment
            initial_application.reload
            expect(initial_application.aasm_state).to eq :approved
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.end_open_enrollment' do
      context "when initial employer successfully completed enrollment period" do

        let(:open_enrollment_close) { TimeKeeper.date_of_record.prev_day }
        let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
        let(:aasm_state) { :enrollment_open }
        let(:open_enrollment_period) { effective_period.min.prev_month..open_enrollment_close }

        include_context "setup initial benefit application" do
          let(:aasm_state) { :enrollment_open }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 7, 24))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment close date passed" do
          before :each do
            allow(::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator).to receive(:call).with(initial_application, Date.new(Date.today.year, 7, 24))
          end

          it "should close open enrollment" do
            subject.end_open_enrollment
            initial_application.reload
            expect(initial_application.aasm_state).to eq :enrollment_closed
          end

          it "invokes pricing determination calculation" do
            expect(::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator).to receive(:call).with(initial_application, Date.new(Date.today.year, 7, 24))
            subject.end_open_enrollment
          end
        end

        context "open enrollment close date in the future" do
          let(:open_enrollment_close) { TimeKeeper.date_of_record.next_day }

          it "should do nothing" do
            subject.begin_open_enrollment
            initial_application.reload
            expect(initial_application.aasm_state).to eq :enrollment_open
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.begin_benefit' do

      context "when initial employer completed open enrollment and ready to begin benefit" do

        let(:applcation_state) { :enrollment_closed }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:aasm_state) {  applcation_state }
        end

        before(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 24))
        end

        after(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "made binder payment" do
          let(:applcation_state) { :enrollment_eligible }

          before do
            allow(initial_application).to receive(:transition_benefit_package_members).and_return(true)
          end

          it "should begin benefit" do
            subject.begin_benefit
            initial_application.reload
            expect(initial_application.aasm_state).to eq :active
          end
        end

        context "binder not paid" do

          let(:aasm_state) {  :canceled } # benefit application will be moved to canceled state when binder payment is missed.

          it "should raise an exception" do
            expect{subject.begin_benefit}.to raise_error(StandardError)
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.end_benefit' do
      context "when employer application exists with active application" do

        let(:market_inception) { TimeKeeper.date_of_record.year - 1 }


        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year - 1, 8, 1) }
          let(:aasm_state) { :active }
        end

        before(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 8, 1))
        end

        after(:all) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "when end date is in past" do

          before do
            allow(initial_application).to receive(:transition_benefit_package_members).and_return(true)
          end

          it "should close benefit" do
            subject.end_benefit
            initial_application.reload
            expect(initial_application.aasm_state).to eq :expired
          end
        end
      end
    end

    describe '.cancel' do
    end

    describe '.terminate' do
    end

    describe '.reinstate' do
    end
  end
end

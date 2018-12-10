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

      before(:each) do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
      end

      after(:each) do
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

        let(:open_enrollment_begin) { Date.new(TimeKeeper.date_of_record.year, 7, 3) }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:open_enrollment_period) { open_enrollment_begin..(effective_period.min - 10.days) }
          let(:aasm_state) { :draft }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 4))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment start date in the past" do

          context "and the benefit_application passes business policy validation" do

            it "should submit application with immediate open enrollment" do
              subject.submit_application
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_open
              expect(initial_application.open_enrollment_period.begin.to_date).to eq TimeKeeper.date_of_record
            end
          end

          context "and the benefit_application fails business policy validation" do
            let(:business_policy) { instance_double("some_policy", fail_results: { business_rule: "failed validation" })}

            it "application should transition into :draft state" do
              allow(subject).to receive(:business_policy).and_return(business_policy)
              allow(subject).to receive(:business_policy_satisfied_for?).with(:submit_benefit_application).and_return(false)

              subject.submit_application
              initial_application.reload
              expect(initial_application.aasm_state).to eq :draft
            end
          end

        end

        context "open enrollment start date in the future" do
          let(:open_enrollment_begin) { Date.new(TimeKeeper.date_of_record.year, 7, 5) }

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

      context 'Invoke force_submit_application' do
        let(:application_errors) do
          { 'invalid_application' => 'Invalid application error' }
        end
        let(:application_warnings) do
          { 'invalid_application' => 'Invalid application warning' }
        end
        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context 'When is_application_valid? OR is_application_eligible? AND may_submit_for_review? are is false' do

          it 'should return notice, warnings and state could not be changed' do
            allow(subject).to receive(:application_errors).and_return(application_errors)
            allow(initial_application).to receive(:may_submit_for_review?).and_return(false)
            subject.force_submit_application
            initial_application.reload
            expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed')
            expect(subject.messages['warnings']).to eq(['Invalid application error'])
            expect(subject.errors).to eq([])
            expect(initial_application.aasm_state).to eq :active
          end
        end

        context 'When is_application_valid? OR is_application_eligible? is false AND may_submit_for_review? is true' do
          context 'state is not draft' do
            it 'should return error' do
              allow(subject).to receive(:application_errors).and_return(application_errors)
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages).to eq({})
              expect(subject.errors).to eq(["Event 'submit_for_review' cannot transition from 'active'. "])
              expect(initial_application.aasm_state).to eq :active
            end
          end

          context 'state is draft' do
            before { initial_application.update_attribute(:aasm_state, 'draft') }
            it 'should return notice, warnings and state could not be changed' do
              allow(subject).to receive(:application_errors).and_return(application_errors)
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully submitted for review.')
              expect(subject.messages['warnings']).to eq(['Invalid application error'])
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :pending
            end
          end
        end

        context 'When is_application_valid? AND is_application_eligible? are true' do
          context 'when benefit_application may_approve_application? is false' do
            it 'should return notice Plan Year could not be processed' do
              allow(initial_application).to receive(:may_approve_application?).and_return(false )
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :active
            end
          end

          context 'when benefit_application may_approve_application? is true and state is active then' do
            it 'should return error' do
              allow(initial_application).to receive(:may_approve_application?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages).to eq({})
              expect(subject.errors).to eq(["Event 'auto_approve_application' cannot transition from 'active'. "])
              expect(initial_application.aasm_state).to eq :active
            end
          end

          context 'when benefit_application may_approve_application? is true and state is draft then' do
            before { initial_application.update_attributes(aasm_state: 'draft') }

            it 'should return error if today is less than open_enrollment_period' do
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              allow(subject).to receive(:today).and_return(initial_application.open_enrollment_period.begin - 1.year)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages).to eq({})
              expect(subject.errors).to eq(['Employer(s) Plan Year date has not matched.'])
              expect(initial_application.aasm_state).to eq :approved
            end

            it 'should return notice, warnings and state could not be changed' do
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully published.')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :enrollment_open
            end
          end
        end
      end

      context "renewal application in draft state" do

        let(:scheduled_event)  {BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents}

        let!(:renewal_application)  { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application).renew_application[1] }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(renewal_application) }

        context "today is prior to date for force publish" do
          before(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 8, 15))
          end

          after(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          it "should not change the benefit application" do
            scheduled_event.advance_day(TimeKeeper.date_of_record)
            expect(renewal_application.aasm_state).to eq :draft
          end

        end

      context "today is date for force publish", dbclean: :after_each do
          let(:open_enrollment_begin) { Date.new(TimeKeeper.date_of_record.year, 7, 3) }

          include_context "setup initial benefit application" do
            let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
            let(:open_enrollment_period) { open_enrollment_begin..(effective_period.min - 10.days) }
            let(:aasm_state) { :draft }
          end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 4))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

          it "should transition the benefit_application into :enrollment_open" do
              subject.submit_application
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_open
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
          let(:open_enrollment_period) { (effective_period.min - 2.months)..open_enrollment_begin }
          let(:aasm_state) { :approved }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
        end

        after(:each) do
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
          let(:benefit_sponsorship_state) { :initial_enrollment_open }
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
            initial_application.benefit_sponsorship.update_attributes(aasm_state: :initial_enrollment_open)
            allow(::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator).to receive(:call).with(initial_application, Date.new(Date.today.year, 7, 24))
          end

          context "and the benefit_application enrollment passes eligibility policy validation" do
            let(:business_policy) { instance_double("some_policy", success_results: { business_rule: "validation passed" })}
            before do
              allow(subject).to receive(:business_policy).and_return(business_policy)
              allow(subject).to receive(:business_policy_satisfied_for?).with(:end_open_enrollment).and_return(true)
            end
            it "should close open enrollment" do
              subject.end_open_enrollment
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_closed
            end
          end

          context "and the benefit_application enrollment fails eligibility policy validation" do
            let(:business_policy) { instance_double("some_policy", fail_results: { business_rule: "failed validation" })}

            it "should close open enrollment and transition into :enrollment_ineligible state" do
              allow(subject).to receive(:business_policy).and_return(business_policy)
              allow(subject).to receive(:business_policy_satisfied_for?).with(:end_open_enrollment).and_return(false)

              subject.end_open_enrollment
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_ineligible
              expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
            end
          end


          it "invokes pricing determination calculation" do
            expect{::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator.call(initial_application, Date.new(Date.today.year, 7, 24))}.not_to raise_error
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

        let(:application_state) { :enrollment_closed }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:aasm_state) {  application_state }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 24))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "made binder payment" do
          let(:application_state) { :enrollment_eligible }

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

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 8, 1))
        end

        after(:each) do
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

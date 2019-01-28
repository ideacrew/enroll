require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"


module BenefitSponsors
  RSpec.describe "initial employer monthly transmission", dbclean: :after_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:effective_on) { current_effective_date }
    let(:aasm_state) { :enrollment_eligible }
    let(:benefit_sponsorship_state) { :initial_enrollment_eligible }
    let(:initial_benefit_sponsorship) {initial_application.benefit_sponsorship}
    let!(:initial_employer_transmission_day) { Date.new(current_effective_date.prev_month.year,current_effective_date.prev_month.month, 26)}


      context "should trigger monthly inital employer on transmission day i.e 26 of the month" do
        it "should notify inital employer event" do
          # 26 monthly initial employer
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(initial_employer_transmission_day)
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: initial_benefit_sponsorship.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(initial_employer_transmission_day)
        end
      end

    context "should trigger late inital employer's that come b/w after transmission day to end of month" do

      it "should notify inital employer event" do
        # 27..31 late employers
        ((initial_employer_transmission_day + 1.day)..effective_on).to_a.each do |date|
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(date)
          initial_application.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :enrollment_eligible, transition_at: date.prev_day)
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: initial_benefit_sponsorship.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(date)
        end
      end
    end

    context "should not trigger employer's who already transmitted on 26th of the month in late employer extended period." do

      before do
        initial_application.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :enrollment_eligible, transition_at: initial_employer_transmission_day - 4.day)
      end

      it "should not notify event" do
        ((initial_employer_transmission_day + 1.day)..effective_on).to_a.each do |date|
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(date)
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: initial_benefit_sponsorship.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(date)
        end
      end
    end
  end

  RSpec.describe "renewal employer monthly transmission", dbclean: :after_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup renewal application"

    let(:renewal_state)           { :enrollment_eligible }
    let(:renewal_effective_date)  { TimeKeeper.date_of_record.next_month.beginning_of_month  }
    let!(:renewal_employer_transmission_day) { Date.new(renewal_effective_date.prev_month.year,renewal_effective_date.prev_month.month, 26)}

    context "should trigger monthly renewal employer on transmission day i.e 26 of the month" do

      before do
        benefit_sponsorship.aasm_state = :active
        benefit_sponsorship.save
      end

      it "should notify renewal employer event" do
        # 26th monthly renewal transmission day for employer
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(renewal_employer_transmission_day)
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: benefit_sponsorship.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(renewal_employer_transmission_day)
      end
    end

    context "should trigger late renewal employer's that come b/w after transmission day to end of month" do

      before do
        benefit_sponsorship.aasm_state = :active
        benefit_sponsorship.save
      end

      it "should notify renewal employer event" do
        # 27..31 for late renewal employers
        ((renewal_employer_transmission_day + 1.day)..renewal_effective_date).to_a.each do |date|
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(date)
          renewal_application.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :enrollment_eligible, transition_at: date.prev_day)
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: benefit_sponsorship.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(date)
        end
      end
    end

    context "should not trigger renewal employer's who already transmitted on 26th of the month in late employer extended period." do

      before do
        benefit_sponsorship.aasm_state = :active
        benefit_sponsorship.save
        renewal_application.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :enrollment_eligible, transition_at: renewal_employer_transmission_day - 4.day)
      end

      it "should not notify event" do
        ((renewal_employer_transmission_day + 1.day)..renewal_effective_date).to_a.each do |date|
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(date)
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: benefit_sponsorship.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(date)
        end
      end
    end
  end
end






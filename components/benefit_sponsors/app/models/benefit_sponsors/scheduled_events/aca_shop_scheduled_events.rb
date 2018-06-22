module BenefitSponsors
  module ScheduledEvents
    class AcaShopScheduledEvents

      include ::Acapi::Notifiers
      include Config::AcaModelConcern

      attr_reader :new_date

      def self.advance_day(new_date)
        self.new(new_date)
      end

      def initialize(new_date)
        @new_date = new_date
        shop_daily_events
        auto_submit_renewal_applications
        auto_transmit_monthly_benefit_sponsors
        close_enrollment_quiet_period
      end

      def shop_daily_events
        process_events_for { open_enrollment_begin }
        process_events_for { open_enrollment_end }
        process_events_for { benefit_begin }
        process_events_for { benefit_end }
        process_events_for { benefit_termination }
        process_events_for { benefit_renewal }
      end

      def open_enrollment_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_open_enrollment?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          execute_sponsor_event(benefit_sponsorship, :begin_open_enrollment)
        end
      end

      def open_enrollment_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_open_enrollment?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          execute_sponsor_event(benefit_sponsorship, :end_open_enrollment)
        end
      end

      def benefit_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          execute_sponsor_event(benefit_sponsorship, :begin_sponsor_benefit)   
        end
      end

      def benefit_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          execute_sponsor_event(benefit_sponsorship, :end_sponsor_benefit)
        end
      end

      def benefit_termination
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_terminate_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          execute_sponsor_event(benefit_sponsorship, :terminate_sponsor_benefit)
        end
      end

      def benefit_renewal
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_renew_application?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          execute_sponsor_event(benefit_sponsorship, :renew_sponsor_benefit)
        end
      end

      def auto_submit_renewal_applications
        if new_date.day == Settings.aca.shop_market.renewal_application.force_publish_day_of_month
          effective_on = new_date.next_month.beginning_of_month
          benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_auto_submit_application?(effective_on)

          benefit_sponsorships.each do |benefit_sponsorship|
            execute_sponsor_event(benefit_sponsorship, :auto_submit_application)
          end
        end
      end

      def auto_transmit_monthly_benefit_sponsors
        if aca_shop_market_transmit_scheduled_employers
          if (new_date.prev_day.mday + 1) == aca_shop_market_employer_transmission_day_of_month
            transmit_scheduled_benefit_sponsors(new_date)
          end
        end
      end

      def transmit_scheduled_benefit_sponsors(new_date, feins=[])
        start_on = new_date.next_month.beginning_of_month
        benefit_sponsors = BenefitSponsors::BenefitSponsors::BenefitSponsorship
        benefit_sponsors = benefit_sponsors.find_by_feins(feins) if feins.any?

        benefit_sponsors.may_renew_application?(start_on.prev_year).each do |benefit_sponsorship|
          transmit_event(benefit_sponsorship, :transmit_renewal_eligible_event) if benefit_sponsorship.is_renewal_transmission_eligible?
          transmit_event(benefit_sponsorship, :transmit_renewal_carrier_drop_event) if benefit_sponsorship.is_renewal_carrier_drop?
        end

        benefit_sponsors.may_transmit_initial_enrollment?(start_on).each do |benefit_sponsorship|
          transmit_event(benefit_sponsorship, :transmit_initial_eligible_event)
        end
      end

      def close_enrollment_quiet_period
        if new_date.prev_day.mday == Settings.aca.shop_market.initial_application.quiet_period.mday
          effective_on = (new_date.prev_day.beginning_of_month - Settings.aca.shop_market.initial_application.quiet_period.month_offset.months).to_s(:db)
          notify("acapi.info.events.employer.initial_employer_quiet_period_ended", {:effective_on => effective_on})
        end
      end

      private

      def execute_sponsor_event(benefit_sponsorship, event)
        begin
          business_policy = business_policy_for(benefit_sponsorship, event)
          event_service   = sponsor_service_for(benefit_sponsorship)
          event_service.execute(benefit_sponsorship, event, business_policy)
        rescue Exception => e 
        end
      end

      def transmit_event(benefit_sponsorship, event)
        sponsorship_service.benefit_sponsorship = benefit_sponsorship
        sponsorship_service.send(event)
      end

      def business_policy_for(benefit_sponsorship, event_name)
        sponsor_policy.business_policies_for(benefit_sponsorship, event_name)
      end

      def sponsor_service_for(benefit_sponsorship)
        if benefit_sponsorship.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
          sponsorship_service
        end
      end

      def sponsorship_service
        return @sponsorship_service if defined? @sponsorship_service
        @sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(new_date: new_date)
      end

      def sponsor_policy
        return @sponsor_policy if defined?(@sponsor_policy)
        @sponsor_policy = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipPolicy.new
      end

      def process_events_for(&block)
        begin
          block.call
        rescue Exception => e
        end
      end
    end
  end
end

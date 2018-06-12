module BenefitSponsors
  module BenefitSponsorships
    class AcaShopScheduledEvent

      attr_reader :new_date

      def self.advance_day(new_date)
        self.new(new_date)
      end

      def initialize(new_date)
        @new_date = new_date
        shop_daily_events
        trigger_force_submit_applications
        generate_employer_group_files
        end_enrollment_quiet_period
      end

      def is_event_date_valid?(new_date)
        if new_date.day == Settings.aca.shop_market.renewal_application.force_publish_day_of_month
          return true
        end
      end

      def trigger_force_submit_applications
        if is_event_date_valid?(:force_submit)

          benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_open_enrollment?(new_date)
        end
      end

      def generate_employer_group_files
      end

      def end_enrollment_quiet_period
      end

      def shop_daily_events
        process_events_for { open_enrollment_begin }
        process_events_for { open_enrollment_end }
        process_events_for { benefit_begin }
        process_events_for { benefit_end }
        process_events_for { benefit_termination }
        process_events_for { benefit_renewal }
      end

      def business_policy_for(event)

      end

      def event_service_for(benefit_sponsorship)
        if benefit_sponsorship.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
          sponsorship_service
        end
      end

      def process_event(benefit_sponsorship, event)
        business_policy = business_policy_for(event)
        event_service   = event_service_for(benefit_sponsorship)
        event_service.execute(benefit_sponsorship, event, business_policy)
      end

      def open_enrollment_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_open_enrollment?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          process_application(benefit_sponsorship, :begin_open_enrollment)
        end
      end

      def open_enrollment_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_open_enrollment?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          process_application(benefit_sponsorship, :close_open_enrollment)        
        end
      end

      def benefit_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          process_application(benefit_sponsorship, :close_open_enrollment)        

          # sponsorship_service.benefit_sponsorship = benefit_sponsorship
          # sponsorship_service.begin_sponsor_benefit
        end
      end

      def benefit_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service.benefit_sponsorship = benefit_sponsorship
          sponsorship_service.end_sponsor_benefit
        end
      end

      def benefit_termination
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_terminate_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service.benefit_sponsorship = benefit_sponsorship
          sponsorship_service.terminate_sponsor_benefit
        end
      end

      def benefit_renewal
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_renew_application?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service.benefit_sponsorship = benefit_sponsorship
          sponsorship_service.renew_sponsor_benefit
        end
      end

      def sponsorship_service
        return @sponsorship_service if defined? @sponsorship_service
        @sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(new_date: new_date)
      end

      private

      def process_events_for(&block)
        begin
          block.call
        rescue Exception => e
        end
      end

      def process_event(&block)
        begin
          block.call
        rescue Exception => e
        end
      end
    end
  end
end

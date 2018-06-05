module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorScheduledJobs

      attr_reader :new_date

      def process(new_date)
        @new_date = new_date

        process_applications_for { open_enrollment_begin }
        process_applications_for { open_enrollment_end }
        process_applications_for { benefit_begin }
        process_applications_for { benefit_end }
        process_applications_for { benefit_termination }
        process_applications_for { benefit_renewal }
      end

      def open_enrollment_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_open_enrollment?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service.benefit_sponsorship = benefit_sponsorship
          sponsorship_service.begin_open_enrollment
        end
      end

      def open_enrollment_end
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_end_open_enrollment?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service.benefit_sponsorship = benefit_sponsorship
          sponsorship_service.end_open_enrollment
        end
      end

      def benefit_begin
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_benefit_coverage?(new_date)

        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service.benefit_sponsorship = benefit_sponsorship
          sponsorship_service.begin_sponsor_benefit
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

      def process_applications_for(&block)
        begin
          block.call
        rescue Exception => e
        end
      end

      def process_application(&block)
        begin
          block.call
        rescue Exception => e
        end
      end
    end
  end
end

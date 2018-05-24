module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorTimeKeeperJobs

      attr_reader :new_date

      def process(new_date)
        @new_date = new_date
        process_applications_for { open_enrollment_begin }
        process_applications_for { open_enrollment_end }
        process_applications_for { coverage_begin }
        process_applications_for { coverage_end }
      end

      def may_begin_initial_open_enrollment
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_initial_open_enrollment_on(new_date)
        begin_initial_open_enrollment(benefit_sponsorships)
      end

      def may_begin_renewal_open_enrollment
        benefit_sponsorships = BenefitSponsorships::BenefitSponsorship.may_begin_renewal_open_enrollment_on(new_date)
        begin_renewal_open_enrollment(benefit_sponsorships)
      end

      def begin_initial_open_enrollment(benefit_sponsorships)
        benefit_sponsorships.each do |benefit_sponsorship|
          sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(benefit_sponsorship)
          sponsorship_service.begin_initial_open_enrollment(new_date)
        end
      end

      def begin_renewal_open_enrollment(benefit_sponsorships)
        benefit_sponsorships.each do |benefit_sponsorship|
          begin
            sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(benefit_sponsorship)
            sponsorship_service.begin_renewal_open_enrollment(new_date)
          rescue Exception => e 
          end
        end
      end


      def open_enrollment_begin
        service = AcaShopOpenEnrollmentService.new
        benefit_applications = BenefitApplication.by_open_enrollment_begin_on(new_date).plan_design_approved
        benefit_applications.each do |benefit_application|
          process_application {
            service.begin_open_enrollment(benefit_application)
          }
        end
      end

      def open_enrollment_end
        service = AcaShopOpenEnrollmentService.new
        benefit_applications = BenefitApplication.by_open_enrollment_end_on(new_date).plan_design_approved
        benefit_applications.each do |benefit_application|
          process_application {
            service.close_open_enrollment(benefit_application)
          }
        end
      end

      def coverage_begin; end
      def coverage_end; end

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

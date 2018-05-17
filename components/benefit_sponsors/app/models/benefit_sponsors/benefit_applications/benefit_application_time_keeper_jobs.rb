module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationTimeKeeperJobs

      attr_reader :new_date

      def process(new_date)
        @new_date = new_date
        process_applications_for { open_enrollment_begin }
        process_applications_for { open_enrollment_end }
        process_applications_for { coverage_begin }
        process_applications_for { coverage_end }
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

      def coverage_begin;
      def coverage_end;

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
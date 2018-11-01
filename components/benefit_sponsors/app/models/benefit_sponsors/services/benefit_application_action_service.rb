module BenefitSponsors
  module Services
    class BenefitApplicationActionService

      attr_reader :benefit_application, :args

      def initialize(benefit_application, args)
        @benefit_application = benefit_application
        @benefit_sponsorship = benefit_application.benefit_sponsorship
        @args = args
      end

      def terminate_application
        begin
          failed_results = {}
          # Cancels renewal application
          if benefit_sponsorship.renewal_benefit_application
            service = initialize_service(benefit_sponsorship.renewal_benefit_application)
            result, ba, errors = service.cancel
            map_errors_for(errors, onto: failed_results) if errors.present?
          end

          # Terminates current application
          service = initialize_service(benefit_application)
          result, ba, errors = if args[:end_on] >= TimeKeeper.date_of_record
            service.schedule_enrollment_termination
          else
            service.terminate
          end
          map_errors_for(errors, onto: failed_results) if errors.present?
          [result, ba, failed_results]
        rescue Exception => e
          Rails.logger.error { "Error terminating #{benefit_application.benefit_sponsorship.organization.legal_name}'s benefit application due to #{e.backtrace}" }
        end
      end

      def cancel_application
        begin
          service = initialize_service(benefit_application)
          result, ba, errors = service.cancel
          [result, ba, errors]
        rescue Exception => e
          Rails.logger.error { "Error canceling #{benefit_application.benefit_sponsorship.organization.legal_name}'s benefit application due to #{e.backtrace}" }
        end
      end

      def initialize_service(application)
        BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(application)
      end

      def map_errors_for(errors, onto:)
        errors.each do |k, v|
          onto.add(k, v)
        end
      end


    end
  end
end

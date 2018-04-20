module BenefitSponsors
  module BenefitApplications
    class AcaShopOpenEnrollmentService

      # Observer pattern tied to DateKeeper - Standard Event: OpenEnrollmentClosed
      # Needs to handle exempt applcations

      ## Trigger events can be dates or from UI

      def sponsors_to_close_open_enrollment
        # query all benefit_applications in OE state with open_enrollment_period.max
        @benefit_applications = BenefitSponsors:: by_open_enrollment_end_date
      end

      def begin_open_enrollment(benefit_application)
      end

      def close_open_enrollment(benefit_application)
      end

      def cancel_open_enrollment(benefit_application)
      end

      # Exempt exception handling situation
      def extend_open_enrollment(benefit_application, new_end_date)
      end

      # Exempt exception handling situation
      def retroactive_open_enrollment(benefit_application)
      end


    end
  end
end

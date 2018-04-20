module BenefitSponsors
  module BenefitApplications
    class AcaShopOpenEnrollmentService

      # Observer pattern tied to DateKeeper - Standard Event: OpenEnrollmentClosed
      # Needs to handle exempt applcations

      ## Trigger events can be dates or from UI

      def open_enrollments_past_end_on(date = TimeKeeper.date_of_record)

        # query all benefit_applications in OE state with open_enrollment_period.max < date
        @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date
      end

      def begin_open_enrollment(benefit_application)
        member_enrollments.each { |enrollment| renew_member_enrollment(benefit_application) }
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

      def renew_member_enrollment(renewal_benefit_application, current_member_enrollment)

        renewal_member_enrollment
      end


    end
  end
end

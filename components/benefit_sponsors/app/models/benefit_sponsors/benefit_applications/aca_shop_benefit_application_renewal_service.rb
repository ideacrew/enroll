require 'ostruct'

module BenefitSponsors
  module BenefitApplications
    class AcaShopBenefitApplicationRenewalService

      attr_accessor :benefit_application, :employer_profile, :benefit_sponsorship

      def initialize(benefit_application)
        @benefit_application = benefit_application
        @benefit_sponsorship = benefit_application.benefit_sponsorship
        @employer_profile = @benefit_sponsorship.profile
      end

      def generate_renewal
        return false if is_benefit_applcaition_valid?
        return false if sponsor_had_any_published_benefit_applcation?

        if employer_profile.may_enroll_employer?
          employer_profile.enroll_employer!
        elsif @employer_profile.may_force_enroll?
          employer_profile.force_enroll!
        end

        # move to scehdular if possible
        plan_year_start_on = benefit_application.end_on + 1.day
        plan_year_end_on   = benefit_application.end_on + 1.year
        benefit_applcation = benefit_sponsorship.benefit_applications.first
        schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        renewal_application_start_on = benefit_applcation.end_on + 1.day
        renewal_application_end_on = benefit_applcation.end_on + 1.year

        oe_start_on, oe_end_on = schedular.renewal_open_enrollment_dates(renewal_application_start_on)
        binding.pry
        formed_prams = OpenStruct.new("start_on" => plan_year_start_on,
                                      "end_on" => plan_year_end_on,
                                      "open_enrollment_start_on" => oe_start_on,
                                      "open_enrollment_end_on" => oe_end_on,
                                      "fte_count" => benefit_applcation.fte_count,
                                      "pte_count" => benefit_applcation.pte_count,
                                      "msp_count" => benefit_applcation.msp_count
        )

        fetch_required_data = create_form_params(formed_prams)

        renewal_benefit_applcation = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(benefit_sponsorship, fetch_required_data)

        if renewal_benefit_applcation.may_renew_plan_year?
          renewal_benefit_applcation.renew_plan_year
        end

        # try to raise custom exceptions and logging here!

      end

      def cancel_renewal
        return false if is_benefit_applcaition_valid?
        return false if sponsor_had_any_published_benefit_applcation?

        #need to terminate enrollments for plan year
        # need to delink census Employees benefit group assignments
        # Add custom exceptions in necessary places.

        if benefit_application.may_cancel_renewal?
          benefit_application.cancel_renewal!
        end

      end

      private
      # validations goes here like employer has any published benefit applcations
      def is_benefit_applcaition_valid?
        false
      end


      def sponsor_had_any_published_benefit_applcation?
        false
      end

      def fetch_benefit_groups

      end

      def create_form_params(loded_form)
        {
            effective_period: (format_string_to_date(loded_form.start_on)..format_string_to_date(loded_form.end_on)),
            open_enrollment_period: (format_string_to_date(loded_form.open_enrollment_start_on)..format_string_to_date(loded_form.open_enrollment_end_on)),
            fte_count: loded_form.fte_count,
            pte_count: loded_form.pte_count,
            msp_count: loded_form.msp_count
        }
      end

      def format_string_to_date(date)
        date.to_s
      end

    end
  end
end
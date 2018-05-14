module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService

    def initialize(benefit_sponsorship)
      @benefit_sponsorship = benefit_sponsorship
    end

    # How's this related to benefit application factory?
    def initiate_benefit_application(effective_date)

      benefit_application
    end

    # Trigger : Periodic automatic renewal
    #         : Manual renewals for conversion & error recovery
    # Must have uninterrupted coverage between application periods
    def renew_benefit_application

       benefit_sponsorship.renewal_application

      # Instantiate renewal application
      #   - Get the renewal schedule using schedular and populate dates
      #   - benefit sponsor catalog (build & store)
      #     - check for late rates
      #     - check availability (service areas)
      #
      #   - Renew benefit packages
      #     - construct benefit package
      #       - construct sponsored benefits
      #         - Map products to renewal products
      #     - Add Renewal benefit package assignments
      #   - Trigger notices if any

      benefit_sponsorship = benefit_application.benefit_sponsorship
      renewal_effective_date = benefit_application.effective_period.end.next_day

      renewal_application_dates = renewal_schedule_for(renewal_effective_date)
      renewal_benefit_application = benefit_sponsorship.benefit_applications.build(renewal_application_dates)

      renewal_benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(renewal_effective_date)
      renewal_benefit_application
    end

    def renewal_schedule_for(effective_date)
      open_enrollment_start_on = effective_date - 2.months
      open_enrollment_end_on = Date.new((effective_date - 1.month).year, (effective_date - 1.month).month, Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on)
      {
        effective_period: (effective_date..effective_date.next_year.prev_day),
        open_enrollment_period: (open_enrollment_start_on..open_enrollment_end_on)
      }
    end

    # Must have uninterrupted coverage between periods
    def reinstate_benefit_application(benefit_application)

      benefit_application
    end


    def terminate_benefit_application(benefit_application, termination_date)
      return unless benefit_application.can_terminate_on?(termination_date)

      member_enrollments.each { |enrollment| terminate_member_enrollment(enrollment, termination_date) }
      terminate_application

      benefit_application
    end


    private

    def terminate_member_enrollment(member_enrollment, termination_date)

      member_enrollment
    end

    def member_enrollments(benefit_application)
      benefit_application.benefit_packages.reduce([]) do |list, benefit_package|
        list << benefit_package.benefit_group_assignment.hbx_enrollments
      end
    end


  end
end

module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService

    attr_accessor :benefit_sponsorship, :new_date

    def initialize(benefit_sponsorship: nil, new_date: TimeKeeper.date_of_record)
      @benefit_sponsorship = benefit_sponsorship
      @new_date = new_date
    end

    def begin_open_enrollment
      benefit_application = @benefit_sponsorship.benefit_applications.open_enrollment_begin_on(new_date).first
      application_service.benefit_application = benefit_application

      if benefit_application.is_renewing?
        application_service.begin_renewal_open_enrollment
      else
        application_service.begin_initial_open_enrollment
      end
    end

    def end_open_enrollment

    end

    def begin_sponsor_benefit

    end

    def end_sponsor_benefit

    end

    def terminate_sponsor_benefit

    end

    def renew_sponsor_benefit

    end

    def application_service
      return @application_service if defined? @application_service
      @application_service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new
    end

    def begin_initial_open_enrollment(open_enrollment_begin_on)
      benefit_application = @benefit_sponsorship.initial_open_enrollment_begin_on(open_enrollment_begin_on)
      
      if benefit_application.present?
        application_service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
                
        if application_service.begin_initial_open_enrollment
          log("benefit application enrollment begin successful")
        else
          log(benefit_application.errors.to_s)
        end
      end
    end

    def begin_renewal_open_enrollment(open_enrollment_begin_on)
      benefit_application = @benefit_sponsorship.renewal_open_enrollment_begin_on(open_enrollment_begin_on)
      if benefit_application.present?
        application_service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
        application_service.begin_renewal_open_enrollment
      end
    end


    # # How's this related to benefit application factory?
    # def initiate_benefit_application(effective_date)
    #   benefit_application
    # end

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

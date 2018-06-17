module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService

    attr_accessor :benefit_sponsorship, :new_date

    def initialize(benefit_sponsorship: nil, new_date: TimeKeeper.date_of_record)
      @benefit_sponsorship = benefit_sponsorship
      @new_date = new_date
    end

    def execute(benefit_sponsorship, event_name, business_policy)
      self.benefit_sponsorship = benefit_sponsorship
      if business_policy.is_satisfied?(benefit_sponsorship)
        eval(event_name.to_s)
      end
    end

    def begin_open_enrollment
      benefit_application = benefit_sponsorship.application_may_begin_open_enrollment_on(new_date)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :begin_open_enrollment)
        application_enrollment_service.begin_open_enrollment
      end
    end

    def end_open_enrollment
      benefit_application = benefit_sponsorship.application_may_end_open_enrollment_on(new_date)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :end_open_enrollment)
        application_enrollment_service.close_open_enrollment
      end
    end

    def begin_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_begin_benefit_on(new_date)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :begin_sponsor_benefit)
        application_enrollment_service.begin_benefit
      end
    end

    def end_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_end_benefit_on(new_date)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :end_sponsor_benefit)
        application_enrollment_service.end_benefit
      end
    end

    def terminate_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_terminate_on(new_date)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :terminate_benefit)
        application_enrollment_service.terminate
      end
    end

    def renew_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_renew_effective_on(new_date)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :renew_benefit)
        application_enrollment_service.renew_application
      end
    end

    def auto_submit_application
      effective_on = new_date.next_month.beginning_of_month
      benefit_application = benefit_sponsorship.application_may_auto_submit(effective_on)

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :auto_submit)
        application_enrollment_service.force_submit_application
      end
    end

    private

    def init_application_service(benefit_application, event_name)
      application_enrollment_service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
      application_enrollment_service.business_policy = business_policy_for(benefit_application, event_name)
      application_enrollment_service
    end

    def business_policy_for(benefit_application, event_name)
      enrollment_policy.business_policies_for(benefit_application, event_name)
    end

    def enrollment_policy
      return @enrollment_policy if defined?(@enrollment_policy)
      @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEnrollmentPolicy.new
    end
  end
end

module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService

    attr_accessor :benefit_sponsorship, :new_date

    def initialize(benefit_sponsorship: nil, new_date: TimeKeeper.date_of_record)
      @benefit_sponsorship = benefit_sponsorship
      @new_date = new_date
    end

    def begin_open_enrollment
      benefit_application = benefit_sponsorship.benefit_applications.open_enrollment_begin_on(new_date).approved.first

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :begin_open_enrollment)
        application_enrollment_service.begin_open_enrollment
      end
    end

    def end_open_enrollment
      benefit_application = benefit_sponsorship.benefit_applications.open_enrollment_end_on(new_date).enrolling.first

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :end_open_enrollment)
        application_enrollment_service.close_open_enrollment
      end
    end

    def begin_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.effective_date_begin_on(new_date).enrollment_eligible.first

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :begin_sponsor_benefit)
        application_enrollment_service.begin_benefit
      end
    end

    def end_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.effective_date_end_on(new_date).coverage_effective.first

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :end_sponsor_benefit)
        application_enrollment_service.end_benefit
      end
    end

    def terminate_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.benefit_terminate_on(new_date).first

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :terminate_benefit)
        application_enrollment_service.terminate
      end
    end

    def renew_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.effective_date_end_on(new_date).coverage_effective.first

      if benefit_application.present?
        application_enrollment_service = init_application_service(benefit_application, :renew_benefit)
        application_enrollment_service.renew
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

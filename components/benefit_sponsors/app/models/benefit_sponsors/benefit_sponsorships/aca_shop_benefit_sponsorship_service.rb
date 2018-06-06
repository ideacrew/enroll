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
        service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)

        if benefit_application.is_renewing?
          service.begin_renewal_open_enrollment
        else
          service.begin_initial_open_enrollment
        end
      end
    end

    def end_open_enrollment
      benefit_application = benefit_sponsorship.benefit_applications.open_enrollment_end_on(new_date).enrolling.first

      if benefit_application.present?
        service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
        service.close_open_enrollment
      end
    end

    def begin_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.effective_date_begin_on(new_date).enrollment_eligible.first

      if benefit_application.present?
        service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
        service.begin_benefit
      end
    end

    def end_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.effective_date_end_on(new_date).coverage_effective.first

      if benefit_application.present?
        service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
        service.end_benefit
      end
    end

    def terminate_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.benefit_terminate_on(new_date).first

      if benefit_application.present?
        service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
        service.terminate
      end
    end

    def renew_sponsor_benefit
      benefit_application = benefit_sponsorship.benefit_applications.effective_date_end_on(new_date).coverage_effective.first

      if benefit_application.present?
        service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
        service.renew
      end
    end
  end
end

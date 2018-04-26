module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService


    def initiate_benefit_application(effective_date)

      benefit_application
    end

    # Must have uninterrupted coverage between application periods
    def renew_benefit_application(benefit_application)

      renewal_benefit_application
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

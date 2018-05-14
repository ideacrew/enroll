module BenefitSponsors
  class BenefitApplications::AcaShopBenefitEnrollmentService

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end

    # validate :open_enrollment_date_checks

    def renew
      @benefit_sponsorship = @benefit_application.benefit_sponsorship
      @benefit_application.renew(renewal_benefit_period)
    end

    # benefit_market_catalog - ?
    # benefit_sponsor_catalog
    def terminate
    end

    def reinstate
    end

    def member_participation_percent
      return "-" if eligible_to_enroll_count == 0
      "#{(total_enrolled_count / eligible_to_enroll_count.to_f * 100).round(2)}%"
    end

    def member_participation_percent_based_on_summary
      return "-" if eligible_to_enroll_count == 0
      "#{(enrolled_summary / eligible_to_enroll_count.to_f * 100).round(2)}%"
    end

    # TODO: Fix this method
    def minimum_employer_contribution
      unless benefit_packages.size == 0
        benefit_packages.map do |benefit_package|
          if benefit_package#.sole_source?
            OpenStruct.new(:premium_pct => 100)
          else
            benefit_package.relationship_benefits.select do |relationship_benefit|
              relationship_benefit.relationship == "employee"
            end.min_by do |relationship_benefit|
              relationship_benefit.premium_pct
            end
          end
        end.map(&:premium_pct).first
      end
    end

    def filter_active_enrollments_by_date(date)
      enrollment_proxies = BenefitApplicationEnrollmentsQuery.new(self).call(Family, date)
      return [] if (enrollment_proxies.count > 100)
      enrollment_proxies.map do |ep|
        OpenStruct.new(ep)
      end
    end

    def hbx_enrollments_by_month(date)
      BenefitApplicationEnrollmentsMonthlyQuery.new(self).call(date)
    end

  end
end

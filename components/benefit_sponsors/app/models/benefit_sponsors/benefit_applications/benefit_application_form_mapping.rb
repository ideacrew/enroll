module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationFormMapping

      attr_reader :params

      def initialize(params)
        @benefit_sponsorship = benefit_sponsorship
        @params = params
      end

      def save(form)
        benefit_application = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(benefit_sponsorship: benefit_sponsorship, benefit_applcation: benefit_applcation, params)
      end

      def benefit_sponsorship
        return @benefit_sponsorship if defined? @benefit_sponsorship
        @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params.delete(:benefit_sponsorship_id)
      end

      def benefit_application
        return @benefit_sponsorship if defined? @benefit_application
        @benefit_application = benefit_sponsorship.benefit_applications.find(params.delete(:benefit_application_id))
      end

      def self.benefit_sponsor_catalogs_for(benefit_sponsorship)
        benefit_sponsorship.benefit_sponsor_catalogs
      end
    end
  end
end